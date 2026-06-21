#!/bin/bash
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'
SHOW_POWERCONTROL_NOTICE=0
SHOW_BATTERYCONTROL_NOTICE=0
SHOW_SLEEPCONTROL_NOTICE=0
SHOW_GPUCONTROL_NOTICE=0
TEST_FILE="/etc/init/.boot_test"
echo "${MAGENTA}"
echo "${BOLD}noexec warning can be safely ignored. ${RESET}"
echo
detect_backlight_path() {
    BACKLIGHT_BASE="/sys/class/backlight"
    BRIGHTNESS_PATH=""
    MAX_BRIGHTNESS_PATH=""
    BACKLIGHT_NAME=""

    if [ ! -d "$BACKLIGHT_BASE" ]; then
        echo "No backlight sysfs found at $BACKLIGHT_BASE"
        return 1
    fi
    
    for candidate in intel_backlight amdgpu_bl0 radeon_bl0 panel0-backlight pwm-backlight acpi_video0 backlight; do
        if [ -d "$BACKLIGHT_BASE/$candidate" ]; then
            BACKLIGHT_NAME="$candidate"
            BRIGHTNESS_PATH="$BACKLIGHT_BASE/$candidate/brightness"
            MAX_BRIGHTNESS_PATH="$BACKLIGHT_BASE/$candidate/max_brightness"
            
            if [ -r "$BRIGHTNESS_PATH" ] && [ -r "$MAX_BRIGHTNESS_PATH" ]; then
                break
            else
                BRIGHTNESS_PATH=""
                MAX_BRIGHTNESS_PATH=""
                BACKLIGHT_NAME=""
            fi
        fi
    done

    if [ -z "$BRIGHTNESS_PATH" ] || [ -z "$MAX_BRIGHTNESS_PATH" ]; then
        for dir in "$BACKLIGHT_BASE"/*; do
            if [ -d "$dir" ] && [ -r "$dir/brightness" ] && [ -r "$dir/max_brightness" ]; then
                BACKLIGHT_NAME=$(basename "$dir")
                BRIGHTNESS_PATH="$dir/brightness"
                MAX_BRIGHTNESS_PATH="$dir/max_brightness"
                break
            fi
        done
    fi

    if [ -z "$BRIGHTNESS_PATH" ] || [ -z "$MAX_BRIGHTNESS_PATH" ]; then
        echo "No valid backlight interface found."
        return 1
    fi
}

 detect_cpu_type() {
    CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || echo "unknown")
    IS_INTEL=0
    IS_AMD=0
    IS_ARM=0
    PERF_PATH=""
    PERF_PATHS=()
    TURBO_PATH=""

    case "$CPU_VENDOR" in
        GenuineIntel)
            IS_INTEL=1
            if [ -f "/sys/devices/system/cpu/intel_pstate/max_perf_pct" ]; then
                PERF_PATH="/sys/devices/system/cpu/intel_pstate/max_perf_pct"
                TURBO_PATH="/sys/devices/system/cpu/intel_pstate/no_turbo"
            fi
            ;;
        AuthenticAMD)
            IS_AMD=1
            if [ -f "/sys/devices/system/cpu/amd_pstate/max_perf_pct" ]; then
                PERF_PATH="/sys/devices/system/cpu/amd_pstate/max_perf_pct"
            else
                mapfile -t PERF_PATHS < <(find /sys/devices/system/cpu/cpufreq/ -type f -name 'scaling_max_freq' 2>/dev/null)
            fi
            ;;
        *)
            IS_ARM=1
            mapfile -t PERF_PATHS < <(find /sys/devices/system/cpu/cpufreq/ -type f -name 'scaling_max_freq' 2>/dev/null)
            ;;
    esac
}


detect_gpu_freq() {
    GPU_FREQ_PATH=""
    GPU_MAX_FREQ=""
    GPU_TYPE="unknown"

    # Intel Xe
    if [ -f /sys/class/drm/card0/gt_max_freq_mhz ]; then
        GPU_TYPE="intel"
        GPU_FREQ_PATH="/sys/class/drm/card0/gt_max_freq_mhz"
        GPU_MAX_FREQ=$(sudo cat "$GPU_FREQ_PATH" 2>/dev/null)

    # AMD
    elif [ -f /sys/class/drm/card0/device/pp_od_clk_voltage ]; then
        GPU_TYPE="amd"
        PP_OD_FILE="/sys/class/drm/card0/device/pp_od_clk_voltage"
        mapfile -t SCLK_LINES < <(sudo grep -i '^sclk' "$PP_OD_FILE" 2>/dev/null)
        if [[ ${#SCLK_LINES[@]} -gt 0 ]]; then
            GPU_MAX_FREQ=$(printf '%s\n' "${SCLK_LINES[@]}" \
                | sed -n 's/.*\([0-9]\{1,\}\)[Mm][Hh][Zz].*/\1/p' \
                | sort -nr | head -n1)
        fi
        GPU_FREQ_PATH="$PP_OD_FILE"
        GPU_MAX_FREQ=${GPU_MAX_FREQ:-0}

    # AMD GCN
    elif [ -f /sys/class/drm/card0/device/pp_dpm_sclk ]; then
        GPU_TYPE="amd"
        PP_DPM_SCLK="/sys/class/drm/card0/device/pp_dpm_sclk"
        GPU_MAX_FREQ=$(grep -oi '[0-9]\+mhz' "$PP_DPM_SCLK" | grep -oi '[0-9]\+' | sort -nr | head -n1)
        GPU_FREQ_PATH="$PP_DPM_SCLK"
        GPU_MAX_FREQ=${GPU_MAX_FREQ:-0}

    # Mali / Adreno
    else
        for d in /sys/class/devfreq/*; do
            if echo "$d" | grep -qiE 'mali|gpu'; then
                if [ -f "$d/max_freq" ]; then
                    GPU_TYPE="mali"
                    GPU_FREQ_PATH="$d/max_freq"
                    GPU_MAX_FREQ=$(sudo cat "$GPU_FREQ_PATH" 2>/dev/null)
                    break
                elif [ -f "$d/available_frequencies" ]; then
                    GPU_TYPE="mali"
                    GPU_FREQ_PATH="$d/available_frequencies"
                    GPU_MAX_FREQ=$(sudo tr ' ' '\n' < "$GPU_FREQ_PATH" 2>/dev/null | sort -nr | head -n1)
                    break
                fi
            fi
        done

        # Adreno Fallback
        if [ "$GPU_TYPE" = "unknown" ] && [ -d /sys/class/kgsl/kgsl-3d0 ]; then
            if [ -f /sys/class/kgsl/kgsl-3d0/max_gpuclk ]; then
                GPU_TYPE="adreno"
                GPU_FREQ_PATH="/sys/class/kgsl/kgsl-3d0/max_gpuclk"
                GPU_MAX_FREQ=$(sudo cat "$GPU_FREQ_PATH" 2>/dev/null)
            elif [ -f /sys/class/kgsl/kgsl-3d0/gpuclk ]; then
                GPU_TYPE="adreno"
                GPU_FREQ_PATH="/sys/class/kgsl/kgsl-3d0/gpuclk"
                GPU_MAX_FREQ=$(sudo cat "$GPU_FREQ_PATH" 2>/dev/null)
            fi
        fi
    fi
}

INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"
echo ""
echo "${RESET}${RED}╔${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}╗"
echo "${RESET}${YELLOW}║                                          NOTICE:                                              ║"
echo "${RESET}${RED}║                                                                                               ║"
echo "${RESET}${YELLOW}║             VT-2 (or enabling sudo in crosh) is required to run this installer!               ║"
echo "${RESET}${RED}║               ${RESET}${YELLOW}Must be installed in a location without the noexec mount.${RED}                       ║"
echo "${RESET}${YELLOW}╚${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}═${RESET}${RED}═${RESET}${YELLOW}╝"
echo "${RESET}"

DEFAULT_INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"

if [ -f "$DEFAULT_INSTALL_DIR/.install_path" ]; then
    INSTALL_DIR=$(sudo cat "$DEFAULT_INSTALL_DIR/.install_path")
    echo -e "${CYAN}Found existing Install Path: ${BOLD}$INSTALL_DIR${RESET}"
else
    INSTALL_DIR="$DEFAULT_INSTALL_DIR"
fi

while true; do
    read -rp "${GREEN}Enter desired Install Path - ${RESET}${GREEN}${BOLD}leave blank for default: $INSTALL_DIR:$RESET " choice
    if [ -n "$choice" ]; then
        INSTALL_DIR="${choice}"
    fi
    INSTALL_DIR="${INSTALL_DIR%/}"

    echo -e "\n${CYAN}You entered: ${BOLD}$INSTALL_DIR${RESET}"
    read -rp "${YELLOW}${BOLD}Confirm this install path? Enter key counts as yes!${RESET}${BOLD} (Y/n): ${RESET}" confirm
    case "$confirm" in
        [Yy]* | "")
            sudo mkdir -p "$INSTALL_DIR"
            echo ""
            break
            ;;
        [Nn]*)
            echo -e "${BLUE}Cancelled.${RESET}\n"
            ;;
        *)
            echo -e "${RED}Please answer Y/n.${RESET}"
            ;;
    esac
done

echo "${BLUE}Stopping any existing components of ChromeOS_PowerControl (in case of reinstall)${RESET}"
sudo ectool backlight 1 >/dev/null 2>&1
sudo bash "$INSTALL_DIR/powercontrol" stop 2>/dev/null
echo ""
sudo bash "$INSTALL_DIR/batterycontrol" stop 2>/dev/null
echo ""
sudo bash "$INSTALL_DIR/fancontrol" stop 2>/dev/null
echo ""
sudo bash "$INSTALL_DIR/sleepcontrol" stop 2>/dev/null
sudo /usr/local/bin/sleepcontrol stop 2>/dev/null
echo ""
sudo bash "$INSTALL_DIR/gpucontrol" stop 2>/dev/null
sleep 0.2
#sudo pkill -f "/usr/local/bin/gpucontrol" >/dev/null 2>&1
#sudo pkill -f "/usr/local/bin/fancontrol" >/dev/null 2>&1
#sudo pkill -f "/usr/local/bin/sleepcontrol" >/dev/null 2>&1
#sudo pkill -f "/usr/local/bin/batterycontrol" >/dev/null 2>&1
#sudo pkill -f "/usr/local/bin/powercontrol" >/dev/null 2>&1
echo "$INSTALL_DIR" | sudo tee "$INSTALL_DIR/.install_path" >/dev/null

declare -a files=(
  "powercontrol" "batterycontrol" "fancontrol" "gpucontrol"
  "sleepcontrol" "deep_suspend.sh"
  "Uninstall_ChromeOS_PowerControl.sh"
  "Reinstall_ChromeOS_PowerControl.sh"
  "LICENSE" "version" "arc.sh"
  "no_turbo.conf" "batterycontrol.conf"
  "powercontrol.conf" "fancontrol.conf"
  "gpucontrol.conf" "sleepcontrol.conf"
)

for file in "${files[@]}"; do
    dest="$INSTALL_DIR/$file"

    echo "${BLUE}Downloading $file to $dest...${RESET}"
    if sudo curl -fsSL "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/$file" -o "$dest"; then
        if grep -q "@INSTALL_DIR@" "$dest"; then
            sed -i "s|@INSTALL_DIR@|$INSTALL_DIR|g" "$dest"
        fi
        sudo chmod +x "$dest" 2>/dev/null
    else
        echo "${RED}Failed to download $file. Skipping.${RESET}"
    fi
    sleep 0.1
done

OLD_CONFIG_PATH="$INSTALL_DIR/config.sh"
if [ -d "/home/chronos/user/MyFiles/Downloads" ]; then
    CONFIG_DIR="/home/chronos/user/MyFiles/Downloads/ChromeOS_PowerControl_Config"
    mkdir -p "$CONFIG_DIR"
    else
        CONFIG_DIR="/usr/local/bin/ChromeOS_PowerControl_Config"
    sudo mkdir -p "$CONFIG_DIR"
    sudo chown -R 1000:1000 "$CONFIG_DIR"
    sudo curl -fsSL https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/gui.py -o /bin/powercontrol-gui 2>/dev/null
    sudo chmod +x /bin/powercontrol-gui 2>/dev/null
    alias powercontrol-gui='sudo -E powercontrol-gui' 
    sudo mkdir -p /usr/share/applications/ /usr/share/icons/hicolor/48x48/apps/
    cat <<'EOF' | sudo tee /usr/share/applications/powercontrol-gui.desktop > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=PowerControl
Comment=Get the power to control your CPU, Battery, Fan Curve, GPU, and Sleep for ChromeOS! 
Exec=sudo -E /bin/powercontrol-gui
Icon=powercontrol
Terminal=true
Categories=Utility;System; 
StartupNotify=true
EOF
    sudo curl -Ls https://github.com/shadowed1/ChromeOS_PowerControl/blob/main/icons/powercontrol_200p.png?raw=true -o /usr/share/icons/hicolor/48x48/apps/powercontrol.png 2>/dev/null
fi

NEW_CONFIG_PATH="$CONFIG_DIR/config"
CONFIG_URL="https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/config.sh"
if [ -f "/home/chronos/user/.bashrc" ]; then
    BASHRC="/home/chronos/user/.bashrc"
else
    BASHRC="$HOME/.bashrc"
fi

chard_line=$(grep -F 'source' "$BASHRC" | grep -F '.chardrc')
if [[ -n "$chard_line" ]]; then
    CHARD_ROOT=$(echo "$chard_line" | sed -n 's/.*source[[:space:]]*"\(.*\)\/\.chardrc".*/\1/p')
fi

if [[ -n "$CHARD_ROOT" ]]; then
    echo "${GREEN}Downloading powercontrol-gui to: $CHARD_ROOT ${RESET}"
    sudo -E curl -fsSL "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/gui.py" -o "$CHARD_ROOT/bin/powercontrol-gui" 2>/dev/null
    sudo chmod +x "$CHARD_ROOT/bin/powercontrol-gui" 2>/dev/null
    sudo mkdir -p "$CHARD_ROOT/usr/share/applications/" "$CHARD_ROOT/usr/share/icons/hicolor/48x48/apps/"
        cat <<'EOF' | sudo tee "$CHARD_ROOT/usr/share/applications/powercontrol-gui.desktop" > /dev/null
[Desktop Entry]
Version=1.0
Type=Application
Name=PowerControl
Comment=Get the power to control your CPU, Battery, Fan Curve, GPU, and Sleep for ChromeOS!
Exec=/bin/powercontrol-gui
Icon=powercontrol
Terminal=false
Categories=Utility;System;
StartupNotify=true
EOF
    sudo curl -Ls https://github.com/shadowed1/ChromeOS_PowerControl/blob/main/icons/powercontrol_200p.png?raw=true -o "$CHARD_ROOT/usr/share/icons/hicolor/48x48/apps/powercontrol.png"
fi

sudo cp $INSTALL_DIR/config.sh $INSTALL_DIR/config.sh.bak 2>/dev/null
if [[ -f "$OLD_CONFIG_PATH" ]]; then
    echo "${YELLOW}Found legacy config.sh — migrating to fixed location${RESET}"
    cp "$OLD_CONFIG_PATH" "$NEW_CONFIG_PATH"
    sudo rm "$OLD_CONFIG_PATH"
    sudo chmod 666 "$NEW_CONFIG_PATH" 2>/dev/null

elif [[ -f "$NEW_CONFIG_PATH" ]]; then
    echo "${GREEN}Existing config preserved at:${BOLD} $NEW_CONFIG_PATH"

else
    echo "${RESET}${BLUE}No config found — downloading default config${RESET}"
    if curl -fsSL "$CONFIG_URL" -o "$NEW_CONFIG_PATH"; then
        sudo chmod 644 "$NEW_CONFIG_PATH" 2>/dev/null
    else
        echo "${RESET}${RED}Failed to download default config${RESET}"
    fi
fi

CONFIG_FILE="$NEW_CONFIG_PATH"
echo
FAN_COUNT=$(sudo ectool pwmgetnumfans | awk -F= '{print $2}' | sed -e 's/ //g')

if [ "$FAN_COUNT" -eq 0 ]; then
    echo "${RESET}${GREEN}Passively cooled device detected, skipping FanControl setup.${RESET}"
    echo ""
    SKIP_FANCONTROL=true
    sed -i '/^STARTUP_FANCONTROL=/d' "$CONFIG_FILE" 2>/dev/null
    echo "STARTUP_FANCONTROL=0" >> "$CONFIG_FILE"
else
    SKIP_FANCONTROL=false
fi

#detect_suspend_mode
detect_backlight_path
detect_cpu_type

for d in /sys/class/power_supply/*; do
    [[ -f "$d/capacity" ]] || { continue; }
    [[ -f "$d/status" ]] || { continue; }
    [[ -f "$d/voltage_min_design" ]] || { continue; }

    if [[ -f "$d/type" ]]; then
        read -r type < "$d/type"
        [[ "$type" == "Battery" ]] || { continue; }
    fi

    case "$d" in
        *hid*|*HID*|*stylus*|*pen*)
            continue
            ;;
    esac

    read -r status < "$d/status"
    [[ "$status" != "Unknown" ]] || { continue; }

    capacity=$(cat "$d/capacity")
    echo "${RESET}${GREEN}"
    echo "Battery: ${BOLD}${capacity}%"
    echo "${RESET}"
done

if [ "$IS_INTEL" -eq 1 ]; then
    SHOW_POWERCONTROL_NOTICE=1
fi
echo ""
echo "${RESET}${BLUE}$BACKLIGHT_NAME"
echo "$BRIGHTNESS_PATH"
echo "$MAX_BRIGHTNESS_PATH${RESET}"
echo ""

echo "${RESET}${CYAN}Detected CPU Vendor: $CPU_VENDOR"
echo "PERF_PATH: $PERF_PATH"
echo "PERF_PATHS: ${PERF_PATHS[*]}"
echo "TURBO_PATH: $TURBO_PATH"
echo "$RESET"
sudo chmod +x "$INSTALL_DIR/powercontrol" "$INSTALL_DIR/batterycontrol" "$INSTALL_DIR/fancontrol" "$INSTALL_DIR/gpucontrol" "$INSTALL_DIR/sleepcontrol" "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh" "$INSTALL_DIR/config.sh" 2>/dev/null
sudo touch "$INSTALL_DIR/.batterycontrol_enabled" "$INSTALL_DIR/.powercontrol_enabled" "$INSTALL_DIR/.fancontrol_enabled"
detect_gpu_freq
echo "${MAGENTA}Detected GPU Type: $GPU_TYPE"
echo "GPU_FREQ_PATH: $GPU_FREQ_PATH"
echo "GPU_MAX_FREQ: $GPU_MAX_FREQ"
echo "${RESET}"

LOG_DIR="/var/log"
sudo touch "$LOG_DIR/powercontrol.log" "$LOG_DIR/batterycontrol.log" "$LOG_DIR/fancontrol.log" "$LOG_DIR/gpucontrol.log" "$LOG_DIR/sleepcontrol.log"
sudo chmod 644 "$LOG_DIR/powercontrol.log" "$LOG_DIR/batterycontrol.log" "$LOG_DIR/fancontrol.log" "$LOG_DIR/gpucontrol.log" "$LOG_DIR/sleepcontrol.log" 2>/dev/null
echo "${YELLOW}${BOLD}Log files for PowerControl, BatteryControl, FanControl, GPUControl, and SleepControl are stored in /var/log/$RESET"

USER_HOME="/home/chronos"
echo ""

declare -a ordered_keys=(
  "MAX_TEMP"
  "MAX_PERF_PCT"
  "MIN_TEMP"
  "MIN_PERF_PCT"
  "HOTZONE"
  "CPU_POLL"
  "RAMP_UP"
  "RAMP_DOWN"
  "CHARGE_MAX"
  "FAN_MIN_TEMP"
  "FAN_MAX_TEMP"
  "MIN_FAN"
  "MAX_FAN"
  "FAN_POLL"
  "STEP_UP"
  "STEP_DOWN"
  "GPU_TYPE"
  "GPU_FREQ_PATH"
  "GPU_MAX_FREQ"
  "BATTERY_DELAY"
  "BATTERY_BACKLIGHT"
  "BATTERY_DIM_DELAY"
  "POWER_DELAY"
  "POWER_BACKLIGHT"
  "POWER_DIM_DELAY"
  "AUDIO_DETECTION_BATTERY"
  "AUDIO_DETECTION_POWER"
  #"SUSPEND_MODE"
  #"ORIGINAL_SUSPEND_MODE"
  "LIDSLEEP_BATTERY"
  "LIDSLEEP_POWER"
  "PERF_PATH"
  "PERF_PATHS"
  "TURBO_PATH"
  "ORIGINAL_GPU_MAX_FREQ"
  "PP_OD_FILE"
  "AMD_SELECTED_SCLK_INDEX"
  "IS_AMD"
  "IS_INTEL"
  "IS_ARM"
  "BACKLIGHT_NAME"
  "BRIGHTNESS_PATH"
  "MAX_BRIGHTNESS_PATH"
)

declare -a ordered_categories=("PowerControl" "BatteryControl" "FanControl" "GPUControl" "SleepControl" "Platform Configuration")
declare -A categories=(
  ["PowerControl"]="MAX_TEMP MIN_TEMP MAX_PERF_PCT MIN_PERF_PCT HOTZONE CPU_POLL RAMP_UP RAMP_DOWN"
  ["BatteryControl"]="CHARGE_MAX"
  ["FanControl"]="MIN_FAN MAX_FAN FAN_MIN_TEMP FAN_MAX_TEMP STEP_UP STEP_DOWN FAN_POLL"
  ["GPUControl"]="GPU_MAX_FREQ"
  ["SleepControl"]="BATTERY_DELAY BATTERY_BACKLIGHT BATTERY_DIM_DELAY POWER_DELAY POWER_BACKLIGHT POWER_DIM_DELAY AUDIO_DETECTION_BATTERY AUDIO_DETECTION_POWER LIDSLEEP_BATTERY LIDSLEEP_POWER"
  ["Platform Configuration"]="IS_AMD IS_INTEL IS_ARM PERF_PATH PERF_PATHS TURBO_PATH GPU_TYPE GPU_FREQ_PATH ORIGINAL_GPU_MAX_FREQ PP_OD_FILE AMD_SELECTED_SCLK_INDEX BACKLIGHT_NAME BRIGHTNESS_PATH MAX_BRIGHTNESS_PATH"
)

if [[ -z "${ORIGINAL_GPU_MAX_FREQ}" ]]; then ORIGINAL_GPU_MAX_FREQ=$GPU_MAX_FREQ; fi
if [[ -z "${MAX_TEMP}" ]]; then MAX_TEMP=90; fi
if [[ -z "${MIN_TEMP}" ]]; then MIN_TEMP=63; fi
if [[ -z "${MAX_PERF_PCT}" ]]; then MAX_PERF_PCT=100; fi
if [[ -z "${MIN_PERF_PCT}" ]]; then MIN_PERF_PCT=10; fi
if [[ -z "${HOTZONE}" ]]; then HOTZONE=79; fi
if [[ -z "${CPU_POLL}" ]]; then CPU_POLL=1; fi
if [[ -z "${RAMP_UP}" ]]; then RAMP_UP=10; fi
if [[ -z "${RAMP_DOWN}" ]]; then RAMP_DOWN=10; fi
if [[ -z "${CHARGE_MAX}" ]]; then CHARGE_MAX=77; fi
if [[ -z "${MIN_FAN}" ]]; then MIN_FAN=0; fi
if [[ -z "${MAX_FAN}" ]]; then MAX_FAN=100; fi
if [[ -z "${FAN_MIN_TEMP}" ]]; then FAN_MIN_TEMP=46; fi
if [[ -z "${FAN_MAX_TEMP}" ]]; then FAN_MAX_TEMP=89; fi
if [[ -z "${STEP_UP}" ]]; then STEP_UP=4; fi
if [[ -z "${STEP_DOWN}" ]]; then STEP_DOWN=1; fi
if [[ -z "${FAN_POLL}" ]]; then FAN_POLL=4; fi
if [[ -z "${BATTERY_DELAY}" ]]; then BATTERY_DELAY=13; fi
if [[ -z "${BATTERY_BACKLIGHT}" ]]; then BATTERY_BACKLIGHT=10; fi
if [[ -z "${BATTERY_DIM_DELAY}" ]]; then BATTERY_DIM_DELAY=7; fi
if [[ -z "${POWER_DELAY}" ]]; then POWER_DELAY=24; fi
if [[ -z "${POWER_BACKLIGHT}" ]]; then POWER_BACKLIGHT=18; fi
if [[ -z "${POWER_DIM_DELAY}" ]]; then POWER_DIM_DELAY=12; fi
if [[ -z "${AUDIO_DETECTION_BATTERY}" ]]; then AUDIO_DETECTION_BATTERY=0; fi
if [[ -z "${AUDIO_DETECTION_POWER}" ]]; then AUDIO_DETECTION_POWER=1; fi
#if [[ -z "${ORIGINAL_SUSPEND_MODE}" ]]; then ORIGINAL_SUSPEND_MODE=$SUSPEND_MODE; fi
if [[ -z "${LIDSLEEP_BATTERY}" ]]; then LIDSLEEP_BATTERY=1; fi
if [[ -z "${LIDSLEEP_POWER}" ]]; then LIDSLEEP_POWER=1; fi

declare -A defaults=(
  [MAX_TEMP]=$MAX_TEMP
  [MIN_TEMP]=$MIN_TEMP
  [MAX_PERF_PCT]=$MAX_PERF_PCT
  [MIN_PERF_PCT]=$MIN_PERF_PCT
  [HOTZONE]=$HOTZONE
  [CPU_POLL]=$CPU_POLL
  [RAMP_UP]=$RAMP_UP
  [RAMP_DOWN]=$RAMP_DOWN
  [CHARGE_MAX]=$CHARGE_MAX
  [MIN_FAN]=$MIN_FAN
  [MAX_FAN]=$MAX_FAN
  [FAN_MIN_TEMP]=$FAN_MIN_TEMP
  [FAN_MAX_TEMP]=$FAN_MAX_TEMP
  [STEP_UP]=$STEP_UP
  [STEP_DOWN]=$STEP_DOWN
  [FAN_POLL]=$FAN_POLL
  [GPU_MAX_FREQ]=$GPU_MAX_FREQ
  [GPU_TYPE]=$GPU_TYPE
  [BATTERY_DELAY]=$BATTERY_DELAY
  [POWER_DELAY]=$POWER_DELAY
  [BATTERY_BACKLIGHT]=$BATTERY_BACKLIGHT
  [POWER_BACKLIGHT]=$POWER_BACKLIGHT
  [AUDIO_DETECTION_BATTERY]=$AUDIO_DETECTION_BATTERY
  [AUDIO_DETECTION_POWER]=$AUDIO_DETECTION_POWER
  #[SUSPEND_MODE]=$SUSPEND_MODE
  #[ORIGINAL_SUSPEND_MODE]=$SUSPEND_MODE
  [LIDSLEEP_BATTERY]=$LIDSLEEP_BATTERY
  [LIDSLEEP_POWER]=$LIDSLEEP_POWER
  [PERF_PATH]=$PERF_PATH
  [TURBO_PATH]=$TURBO_PATH
  [GPU_FREQ_PATH]=$GPU_FREQ_PATH
  [ORIGINAL_GPU_MAX_FREQ]=$GPU_MAX_FREQ
  [PP_OD_FILE]=$PP_OD_FILE
  [AMD_SELECTED_SCLK_INDEX]=$AMD_SELECTED_SCLK_INDEX
  [IS_AMD]=$IS_AMD
  [IS_INTEL]=$IS_INTEL
  [IS_ARM]=$IS_ARM
  [BACKLIGHT_NAME]=$BACKLIGHT_NAME
  [BRIGHTNESS_PATH]=$BRIGHTNESS_PATH
  [MAX_BRIGHTNESS_PATH]=$MAX_BRIGHTNESS_PATH
)

if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE" 2>/dev/null
fi

> "$CONFIG_FILE" 

for category in "${ordered_categories[@]}"; do
  echo "# --- ${category} ---" >> "$CONFIG_FILE"
  for key in ${categories[$category]}; do
    if [ -n "${!key+x}" ]; then
      if declare -p "$key" 2>/dev/null | grep -q 'declare -a'; then
        eval "arr=(\"\${${key}[@]}\")"
        printf '%s=(' "$key" >> "$CONFIG_FILE"
        for elem in "${arr[@]}"; do
          printf '"%s" ' "$elem" >> "$CONFIG_FILE"
        done
        echo ")" >> "$CONFIG_FILE"
      else
        val="${!key}"
        echo "$key=$val" >> "$CONFIG_FILE"
      fi
    else
      val="${defaults[$key]}"
      echo "$key=$val" >> "$CONFIG_FILE"
    fi
  done
  echo >> "$CONFIG_FILE"
done
echo "${GREEN}${BOLD}Installing to: $INSTALL_DIR $RESET"
echo ""
    sudo rm -r /usr/local/bin/powercontrol 2>/dev/null
    sudo rm -r /usr/local/bin/batterycontrol 2>/dev/null
    sudo rm -r /usr/local/bin/fancontrol 2>/dev/null
    sudo rm -r /usr/local/bin/gpucontrol 2>/dev/null
    sudo rm -r /usr/local/bin/sleepcontrol 2>/dev/null
    
    sudo ln -sf "$INSTALL_DIR/powercontrol" /usr/local/bin/powercontrol
    sudo ln -sf "$INSTALL_DIR/batterycontrol" /usr/local/bin/batterycontrol
    sudo ln -sf "$INSTALL_DIR/fancontrol" /usr/local/bin/fancontrol
    sudo ln -sf "$INSTALL_DIR/gpucontrol" /usr/local/bin/gpucontrol
    sudo ln -sf "$INSTALL_DIR/sleepcontrol" /usr/local/bin/sleepcontrol
    sudo ln -sf "$INSTALL_DIR/arc.sh" /usr/local/bin/arc

    echo ""
sudo chown 1000:1000 "$CONFIG_DIR/config"
enable_component_on_boot() {
    local COLOR
    local component="$1"
    local config_file="$2"
    local var_name="STARTUP_$(echo "$component" | tr '[:lower:]' '[:upper:]')"
    local target_file="/etc/init/$(basename "$config_file")"

     case "$component" in
        "PowerControl")   COLOR=${CYAN}${BOLD} ;;
        "GPUControl")     COLOR=${MAGENTA}${BOLD} ;;
        "FanControl")     COLOR=${YELLOW}${BOLD} ;;
        "BatteryControl") COLOR=${GREEN}${BOLD} ;;
        "SleepControl")   COLOR=${BLUE}${BOLD} ;;
        *)                COLOR=${RESET} ;;
    esac
    
    read -rp "${COLOR}Do you want $component enabled on boot?${RESET}${BOLD} (Y/n):${RESET} " move_config
    if [[ -z "$move_config" || "$move_config" =~ ^[Yy]$ ]]; then
        sudo cp "$config_file" "$target_file"
        echo "$var_name=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo ""
    else
        echo "$component must be started manually on boot."
        echo "$var_name=0" | sudo tee -a "$CONFIG_FILE" > /dev/null

        if [ -f "$target_file" ]; then
            sudo rm -f "$target_file"
        fi
        echo ""
    fi
}


if sudo touch "$TEST_FILE" 2>/dev/null; then
    sudo rm -f "$TEST_FILE"

    if [[ -z "$link_cmd" || "$link_cmd" =~ ^[Yy]$ ]]; then
        enable_component_on_boot "BatteryControl" "$INSTALL_DIR/batterycontrol.conf"
        enable_component_on_boot "PowerControl" "$INSTALL_DIR/powercontrol.conf"

        if [ "$SKIP_FANCONTROL" = false ]; then
            enable_component_on_boot "FanControl" "$INSTALL_DIR/fancontrol.conf"
        else
            echo "${GREEN}Skipping FanControl boot setup. No fan to control.${RESET}"
            echo ""
        fi

        enable_component_on_boot "GPUControl" "$INSTALL_DIR/gpucontrol.conf"
        enable_component_on_boot "SleepControl" "$INSTALL_DIR/sleepcontrol.conf"
    else
        echo "Skipping boot-time setup since global commands were declined."
    fi
else
    echo "${YELLOW}Rootfs verification must be disabled to allow startup on boot. ${RESET}"
fi

if grep -q '^STARTUP_GPUCONTROL=1' "$CONFIG_FILE"; then
    SHOW_GPUCONTROL_NOTICE=1
fi

if grep -q '^STARTUP_BATTERYCONTROL=1' "$CONFIG_FILE"; then
    SHOW_BATTERYCONTROL_NOTICE=1
fi

if grep -q '^STARTUP_SLEEPCONTROL=1' "$CONFIG_FILE"; then
    SHOW_SLEEPCONTROL_NOTICE=1
fi

if grep -q '^STARTUP_POWERCONTROL=1' "$CONFIG_FILE"; then
    SHOW_POWERCONTROL_NOTICE=1
fi

start_component_now() {
    local component="$1"
    local command="$2"
    local COLOR

    case "$component" in
        "PowerControl")   COLOR=${CYAN}${BOLD} ;;
        "GPUControl")     COLOR=${MAGENTA}${BOLD} ;;
        "FanControl")     COLOR=${YELLOW}${BOLD} ;;
        "BatteryControl") COLOR=${GREEN}${BOLD} ;;
        "SleepControl")   COLOR=${BLUE}${BOLD} ;;
        *)                COLOR=${RESET} ;;
    esac

   read -rp "${COLOR}Do you want to start $component now?${RESET}${BOLD} (Y/n): ${RESET} " start_now
    if [[ -z "$start_now" || "$start_now" =~ ^[Yy]$ ]]; then
        sudo "$command" start
        echo ""

        if [[ "$component" == "GPUControl" ]]; then
            declare -g SHOW_GPUCONTROL_NOTICE=1
        fi

        if [[ "$component" == "SleepControl" ]]; then
            declare -g SHOW_SLEEPCONTROL_NOTICE=1
        fi

    else
        echo "You can run it later with: sudo $command start"
        echo ""
    fi
}

echo
start_component_now "BatteryControl" "$INSTALL_DIR/batterycontrol"
start_component_now "PowerControl" "$INSTALL_DIR/powercontrol"
if [ "$SKIP_FANCONTROL" = false ]; then
    start_component_now "FanControl" "$INSTALL_DIR/fancontrol"
else
    echo "${YELLOW}FanControl start skipped - passively cooled device.${RESET}"
    echo ""
fi
start_component_now "GPUControl" "$INSTALL_DIR/gpucontrol"
start_component_now "SleepControl" "$INSTALL_DIR/sleepcontrol"
sleep 0.2
echo ""
sleep 0.01
echo "                                                       ${RED}████████████${RESET}           "
sleep 0.01
echo "                                                   ${RED}████${RESET}        ${RED}████${RESET}       "
sleep 0.01
echo "                                                 ${RED}██${RESET}              ${YELLOW}██${RESET}     "
sleep 0.01
echo "                                               ${GREEN}██${RESET}     ${BLUE}██████${RESET}     ${YELLOW}██${RESET}   "
sleep 0.01
echo "                                              ${GREEN}██${RESET}     ${BLUE}████████${RESET}     ${YELLOW}██${RESET}  "
sleep 0.01
echo "                                              ${GREEN}██${RESET}     ${BLUE}████████${RESET}     ${YELLOW}██${RESET}  "
sleep 0.01
echo "                                               ${GREEN}██${RESET}     ${BLUE}██████${RESET}     ${YELLOW}██${RESET}   "
sleep 0.01
echo "                                                 ${GREEN}██${RESET}              ${YELLOW}██${RESET}     "
sleep 0.01
echo "                                                   ${GREEN}████${RESET}        ${YELLOW}████${RESET}       "
sleep 0.01
echo "                                                       ${GREEN}████████████${RESET}           "
sleep 0.01
echo ""
sleep 0.01
echo "                                         ${RED}╔═══════════════════════════════╗${RESET}"
sleep 0.01
echo "                                         ${YELLOW}║ ╔═══════════════════════════╗ ║${RESET}"
sleep 0.01
echo "                                         ${GREEN}║ ║ ╔═══════════════════════╗ ║ ║${RESET}"
sleep 0.01
echo "                                         ${RESET}║ ║ ║ ChromeOS_PowerControl ║ ║ ║${RESET}"
sleep 0.01
echo "                                         ${CYAN}║ ║ ╚═══════════════════════╝ ║ ║${RESET}"
sleep 0.01
echo "                                         ${BLUE}║ ╚═══════════════════════════╝ ║${RESET}"
sleep 0.01
echo "                                         ${MAGENTA}╚═══════════════════════════════╝${RESET}"
sleep 0.01
echo ""
sleep 0.01
echo ""
sleep 0.2
echo "                                              Commands with examples:"
sleep 0.01
echo "${CYAN}"
sleep 0.01
echo "╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
sleep 0.01
echo "║                                                  PowerControl:                                                     ║"
sleep 0.01
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
sleep 0.01
echo "║                                                                                                                    ║"
sleep 0.01
echo "║  powercontrol                       # Show status                                                                  ║"
sleep 0.01
echo "║  powercontrol help                  # Help menu                                                                    ║"
sleep 0.01
echo "║  powercontrol monitor               # Toggle on/off live monitoring in terminal                                    ║"
sleep 0.01
echo "║  sudo powercontrol start            # Throttle CPU based on temperature curve                                      ║"
sleep 0.01
echo "║  sudo powercontrol stop             # Restore default CPU settings                                                 ║"
sleep 0.01
echo "║  sudo powercontrol no_turbo 1       # 0 = Enable, 1 = Disable Turbo Boost                                          ║"
sleep 0.01
echo "║  sudo powercontrol max 75           # Set max performance percentage                                               ║"
sleep 0.01
echo "║  sudo powercontrol min 20           # Set minimum performance at max temp                                          ║"
sleep 0.01
echo "║  sudo powercontrol max_temp 86      # Max temperature threshold - Limit is 90°C                                    ║"
sleep 0.01
echo "║  sudo powercontrol min_temp 60      # Min temperature threshold                                                    ║"
sleep 0.01
echo "║  sudo powercontrol hotzone 78       # Temperature threshold for aggressive thermal management                      ║"
sleep 0.01
echo "║  sudo powercontrol cpu_poll 1       # Interval in seconds PowerControl operates at (0.1s to 5s)                    ║"
sleep 0.01
echo "║  sudo powercontrol ramp_up 15       # % in steps CPU will increase in clockspeed per second                        ║"
sleep 0.01
echo "║  sudo powercontrol ramp_down 20     # % in steps CPU will decrease in clockspeed per second                        ║"
sleep 0.01
echo "║  sudo powercontrol startup          # Copy or Remove no_turbo.conf & powercontrol.conf at: /etc/init/              ║"
sleep 0.01
echo "║                                                                                                                    ║"
sleep 0.01
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
sleep 0.2
echo "${RESET}${GREEN}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
sleep 0.01
echo "║                                                 BatteryControl:                                                    ║"
sleep 0.01
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
sleep 0.01
echo "║                                                                                                                    ║"
sleep 0.01
echo "║  batterycontrol               # Check BatteryControl status                                                        ║"
sleep 0.01
echo "║  batterycontrol monitor       # Toggle on/off live monitoring in terminal                                          ║"
sleep 0.01
echo "║  batterycontrol help          # Help menu                                                                          ║"
sleep 0.01
echo "║  batterycontrol monitor       # Monitor batterycontrol activity                                                    ║"
sleep 0.01
echo "║  sudo batterycontrol start    # Start BatteryControl                                                               ║"
sleep 0.01
echo "║  sudo batterycontrol stop     # Stop BatteryControl                                                                ║"
sleep 0.01
echo "║  sudo batterycontrol 77       # Charge limit set to 77% - minimum of 14% allowed                                   ║"
sleep 0.01
echo "║  sudo batterycontrol usage    # Monitor power consumption in real-time                                             ║"
sleep 0.01
echo "║  sudo batterycontrol startup  # Copy or Remove batterycontrol.conf at: /etc/init/                                  ║"
sleep 0.01
echo "║                                                                                                                    ║"
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
sleep 0.2
echo "${RESET}${YELLOW}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
sleep 0.01
echo "║                                                  FanControl:                                                       ║"
sleep 0.01
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
sleep 0.01
echo "║                                                                                                                    ║"
sleep 0.01
echo "║  fancontrol                       # Show FanControl status                                                         ║"
sleep 0.01
echo "║  fancontrol help                  # Help menu                                                                      ║"
sleep 0.01
echo "║  fancontrol monitor               # Toggle on/off live monitoring in terminal                                      ║"
sleep 0.01
echo "║  sudo fancontrol start            # Start FanControl                                                               ║"
sleep 0.01
echo "║  sudo fancontrol stop             # Stop FanControl                                                                ║"
sleep 0.01
echo "║  sudo fancontrol min_temp 48      # Min temp threshold                                                             ║"
sleep 0.01
echo "║  sudo fancontrol max_temp 81      # Max temp threshold - Limit is 90°C                                             ║"
sleep 0.01
echo "║  sudo fancontrol min 0            # Min fan speed %                                                                ║"
sleep 0.01
echo "║  sudo fancontrol max 100          # Max fan speed %                                                                ║"
sleep 0.01
echo "║  sudo fancontrol step_up 20       # Fan step-up %                                                                  ║"
sleep 0.01
echo "║  sudo fancontrol step_down 1      # Fan step-down %                                                                ║"
sleep 0.01
echo "║  sudo fancontrol poll 2           # FanControl polling rate in seconds (1 to 10s)                                  ║"
sleep 0.01
echo "║  sudo fancontrol startup          # Copy or Remove fancontrol.conf at: /etc/init/                                  ║"
sleep 0.01
echo "║  sudo powercontrol limits         # See your CPU's boost limits in seconds and Watts (x86_64 only)                 ║"
sleep 0. 01
echo "║                                                                                                                    ║"
sleep 0.01
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
sleep 0.2
echo "${RESET}${MAGENTA}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                   GPUControl:                                                      ║"
sleep 0.01
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
sleep 0.01
echo "║                                                                                                                    ║"
sleep 0.01
echo "║  gpucontrol                     # Show current GPU info and frequency                                              ║"
sleep 0.01
echo "║  gpucontrol help                # Help menu                                                                        ║"
sleep 0.01
echo "║  gpucontrol monitor             # Monitor GPU clockspeed in real-time                                              ║"
sleep 0.01
echo "║  sudo gpucontrol start          # Start GPUControl                                                                 ║"
sleep 0.01
echo "║  sudo gpucontrol stop           # Stop GPUControl                                                                  ║"
sleep 0.01
echo "║  sudo gpucontrol restore        # Restore GPU max frequency to original value                                      ║"
sleep 0.01
echo "║  sudo gpucontrol 700            # Set GPU max frequency to 700 MHz                                                 ║"
sleep 0.01
echo "║  sudo gpucontrol startup        # Copy or Remove gpucontrol.conf at: /etc/init/                                    ║"
sleep 0.01
echo "║                                                                                                                    ║"
sleep 0.01
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
sleep 0.2
echo "${RESET}${BLUE}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
echo "║                                                  SleepControl                                                      ║"
sleep 0.01
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
sleep 0.01
echo "║                                                                                                                    ║"
sleep 0.01
echo "║  sleepcontrol                       # Show SleepControl status                                                     ║"
sleep 0.01
echo "║  sleepcontrol help                  # Help menu                                                                    ║"
sleep 0.01
echo "║  sleepcontrol monitor               # Monitor sleepcontrol's log in realtime (ctrl-c to exit)                      ║"
sleep 0.01
echo "║  sleepcontrol powerd                # Monitor powerd.LATEST log in realtime (ctrl-c to exit)                       ║"
sleep 0.01
echo "║  sudo sleepcontrol start            # Start SleepControl                                                           ║"
sleep 0.01
echo "║  sudo sleepcontrol stop             # Stop SleepControl                                                            ║"
sleep 0.01
echo "║  sudo sleepcontrol battery 3 7 12   # When idle, display dims in 3m -> timeout in 7m -> sleeps in 12m on battery   ║"
sleep 0.01
echo "║  sudo sleepcontrol power 5 15 30    # When idle, display dims in 5m -> timeout -> 15m -> sleeps in 30m plugged-in  ║"
sleep 0.01
echo "║  sudo sleepcontrol battery audio 0  # Disable audio detection on battery; sleep can occur during media playback    ║"
sleep 0.01
echo "║  sudo sleepcontrol power audio 1    # Enable audio detection on power; delaying sleep until audio is stopped       ║"
sleep 0.01
echo "║  sudo sleepcontrol lid battery 1    # Enable sleep on closing the lid on battery.                                  ║"
sleep 0.01
echo "║  sudo sleepcontrol lid power 0      # Disable sleep on closing the lid on power.                                   ║"
sleep 0.01
echo "║  sudo sleepcontrol startup          # Copy or Remove sleepcontrol.conf at: /etc/init/                              ║"
sleep 0.01
echo "║                                                                                                                    ║"
sleep 0.01
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
sleep 0.2
echo "${RESET}${CYAN}${BOLD}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
sleep 0.01
echo "║                                              ChromeOS_PowerControl                                                 ║"
sleep 0.01
echo "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
sleep 0.01
echo "║                                                                                                                    ║"
sleep 0.01
echo "║  powercontrol all               # Show status of all ChromeOS_PowerControl components                              ║"
sleep 0.01
echo "║  powercontrol help_all          # Global help menu                                                                 ║"
sleep 0.01
echo "║  powercontrol gui               # Print commands to install GUI app for Crostini or Chard                          ║"
sleep 0.01
echo "║  arc start                      # Pause Android VM to save CPU usage                                               ║"
sleep 0.01
echo "║  arc stop                       # Resume Android VM                                                                ║"
sleep 0.01
echo "║  sudo powercontrol version      # Check PowerControl version                                                       ║"
sleep 0.01
echo "║  sudo powercontrol startup_all  # Copy or Remove all .conf files at: /etc/init/                                    ║"
sleep 0.01
echo "║  sudo powercontrol reinstall    # Download and reinstall ChromeOS_PowerControl                                     ║"
sleep 0.01
echo "║  sudo powercontrol uninstall    # Run uninstaller                                                                  ║"
sleep 0.01
echo "║                                                                                                                    ║"
sleep 0.01
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
sleep 0.01
echo "   sudo bash "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh"  # Alternate uninstall method"
sleep 0.01
echo " ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════"
sleep 0.01
echo "${RESET}"
sleep 0.2
if [[ "$SHOW_BATTERYCONTROL_NOTICE" -eq 1 ]]; then
echo "${GREEN}"
sleep 0.01
echo "╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
sleep 0.01
echo "║  ${RESET}${GREEN}${BOLD}BatteryControl Notice:${RESET}${GREEN}                                                                                            ║"
sleep 0.01
echo "║  DISABLE Adaptive Charging in Settings → System Preferences → Power to avoid notification spam.                    ║"
sleep 0.01
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
fi

#if [[ "$SHOW_GPUCONTROL_NOTICE" -eq 1 ]]; then
#echo "${MAGENTA}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
#echo "║  ${RESET}${MAGENTA}${BOLD}GPUControl Notice:${RESET}${MAGENTA}                                                                                                ║"
#echo "║  As a precaution GPUControl has a 2 minute delay before applying custom clockspeed on boot.                        ║"
#echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
#fi
sleep 0.2
if [[ "$SHOW_SLEEPCONTROL_NOTICE" -eq 1 ]]; then
echo "${BLUE}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
sleep 0.01
echo "║  ${RESET}${BLUE}${BOLD}SleepControl Notice:${RESET}${BLUE}                                                                                              ║"
sleep 0.01
echo "║  DISABLE Sleep in Settings → System Preferences → Power to allow SleepControl to function properly.                ║"
sleep 0.01
echo "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝${RESET}"
sleep 0.01
echo ""
fi
sleep 0.2
echo "                                      ${RED}╔═══════════════════════════════╗${RESET}"
sleep 0.01
echo "                                      ${YELLOW}║ ╔═══════════════════════════╗ ║${RESET}"
sleep 0.01

echo "                                      ${GREEN}║ ║ ╔═══════════════════════╗ ║ ║${RESET}"
sleep 0.01

echo "                                      ${RESET}║ ║ ║ Installation Complete ║ ║ ║${RESET}"
sleep 0.01

echo "                                      ${CYAN}║ ║ ╚═══════════════════════╝ ║ ║${RESET}"
sleep 0.01

echo "                                      ${BLUE}║ ╚═══════════════════════════╝ ║${RESET}"
sleep 0.01

echo "                                      ${MAGENTA}╚═══════════════════════════════╝${RESET}"
sleep 0.01

echo ""
echo "${CYAN}Run ${BOLD}powercontrol gui${RESET}${CYAN} on how to install and run the GUI app! ${RESET}"
echo ""
