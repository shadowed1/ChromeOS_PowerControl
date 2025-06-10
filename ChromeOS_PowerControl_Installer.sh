#!/bin/bash
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)


detect_cpu_type() {
    CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || echo "unknown")
    IS_INTEL=0
    IS_AMD=0
    IS_ARM=0
    case "$CPU_VENDOR" in
        GenuineIntel)
            IS_INTEL=1
            PERF_PATH="/sys/devices/system/cpu/intel_pstate/max_perf_pct"
            TURBO_PATH="/sys/devices/system/cpu/intel_pstate/no_turbo"
            ;;
        AuthenticAMD)
            IS_AMD=1
            if [ -f "/sys/devices/system/cpu/amd_pstate/max_perf_pct" ]; then
                PERF_PATH="/sys/devices/system/cpu/amd_pstate/max_perf_pct"
            else
                PERF_PATH="/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
            fi
            TURBO_PATH=""
            ;;
        *)
            IS_ARM=1
            PERF_PATH="/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
            TURBO_PATH=""
            ;;
    esac
}
detect_gpu_freq() {
    GPU_FREQ_PATH=""
    GPU_MAX_FREQ=""
    # Xe
    if [ -f "/sys/class/drm/card0/gt_max_freq_mhz" ]; then
        GPU_FREQ_PATH="/sys/class/drm/card0/gt_max_freq_mhz"
        GPU_MAX_FREQ=$(cat "$GPU_FREQ_PATH")
        GPU_TYPE="intel"
        return
    fi
    # Radeon
    if [ -f "/sys/class/drm/card0/device/pp_dpm_sclk" ]; then
        GPU_FREQ_PATH="/sys/class/drm/card0/device/pp_dpm_sclk"
        MAX_MHZ=$(grep -oP '[0-9]+Mhz' "$GPU_FREQ_PATH" | sed 's/Mhz//' | sort -nr | head -n1)
        GPU_MAX_FREQ=$(( MAX_MHZ * 1000 )) 
        GPU_TYPE="amd"
        return
    fi
    # Mali
    if [ -d "/sys/class/devfreq/mali0" ]; then
        if [ -f "/sys/class/devfreq/mali0/max_freq" ]; then
            GPU_FREQ_PATH="/sys/class/devfreq/mali0/max_freq"
            GPU_MAX_FREQ=$(cat "$GPU_FREQ_PATH")
            GPU_TYPE="mali"
            return
        elif [ -f "/sys/class/devfreq/mali0/available_frequencies" ]; then
            GPU_FREQ_PATH="/sys/class/devfreq/mali0/available_frequencies"
            MAX_FREQ=$(tr ' ' '\n' < "$GPU_FREQ_PATH" | sort -nr | head -n1)
            GPU_MAX_FREQ=$MAX_FREQ
            GPU_TYPE="mali"
            return
        fi
    fi
    # Adreno
    if [ -d "/sys/class/kgsl/kgsl-3d0" ]; then
        if [ -f "/sys/class/kgsl/kgsl-3d0/max_gpuclk" ]; then
            GPU_FREQ_PATH="/sys/class/kgsl/kgsl-3d0/max_gpuclk"
            GPU_MAX_FREQ=$(cat "$GPU_FREQ_PATH")
            GPU_TYPE="adreno"
            return
        elif [ -f "/sys/class/kgsl/kgsl-3d0/gpuclk" ]; then
            GPU_FREQ_PATH="/sys/class/kgsl/kgsl-3d0/gpuclk"
            GPU_MAX_FREQ=$(cat "$GPU_FREQ_PATH")
            GPU_TYPE="adreno"
            return
        fi
    fi
    GPU_FREQ_PATH=""
    GPU_MAX_FREQ=""
    GPU_TYPE="unknown"
}

echo ""
echo "${RED}VT-2 (or enabling sudo in crosh) is ${RESET}${BOLD}${RED}required${RESET}${RED} to run this installer.$RESET"
echo "${YELLOW}Must be installed in a location without the ${RESET}${MAGENTA}${BOLD}noexec mount.$RESET"
echo ""
read -rp "${GREEN}Enter desired Install Path - ${RESET}${GREEN}${BOLD}leave blank for default: /usr/local/bin/ChromeOS_PowerControl:$RESET " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin/ChromeOS_PowerControl}"
INSTALL_DIR="${INSTALL_DIR%/}"

echo ""
sudo mkdir -p "$INSTALL_DIR"

declare -a files=(
  "powercontrol" "batterycontrol" "fancontrol" "gpucontrol"
  "Uninstall_ChromeOS_PowerControl.sh" "LICENSE" "README.md"
  "no_turbo.conf" "batterycontrol.conf" "powercontrol.conf"
  "fancontrol.conf" "config.sh"
)

for file in "${files[@]}"; do
    if [[ "$file" == "config.sh" && -f "$INSTALL_DIR/$file" ]]; then
        echo "${GREEN}Skipping existing config: $INSTALL_DIR/$file ${RESET}"
        echo ""
        continue
    fi
    curl -L "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/$file" -o "$INSTALL_DIR/$file"
    echo "$INSTALL_DIR/$file downloaded."
    echo ""
done

declare -a files=(".powercontrol_conf.sh" ".batterycontrol_conf.sh" ".fancontrol_conf.sh")
for file in "${files[@]}"; do
    curl -L "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/$file" -o /usr/local/bin/$file
    echo "/usr/local/bin/$file downloaded."
    echo ""
done

detect_cpu_type
echo "${CYAN}Detected CPU Vendor: $CPU_VENDOR"
echo "PERF_PATH: $PERF_PATH"
echo "TURBO_PATH: $TURBO_PATH"
echo "$INSTALL_DIR" | sudo tee /usr/local/bin/.ChromeOS_PowerControl.install_dir > /dev/null
echo "$RESET"
sudo chmod +x "$INSTALL_DIR/powercontrol" "$INSTALL_DIR/batterycontrol" "$INSTALL_DIR/fancontrol" "$INSTALL_DIR/gpucontrol" "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh" "$INSTALL_DIR/config.sh"
sudo touch "$INSTALL_DIR/.batterycontrol_enabled" "$INSTALL_DIR/.powercontrol_enabled" "$INSTALL_DIR/.fancontrol_enabled"
sudo touch "$INSTALL_DIR/.fancontrol_pid" "$INSTALL_DIR/.fancontrol_tail_fan_monitor.pid" "$INSTALL_DIR/.batterycontrol_pid" "$INSTALL_DIR/.powercontrol_tail_fan_monitor.pid" "$INSTALL_DIR/.powercontrol_pid"

detect_gpu_freq
echo "${MAGENTA}Detected GPU Type: $GPU_TYPE"
echo "GPU_FREQ_PATH: $GPU_FREQ_PATH"
echo "GPU_MAX_FREQ: $GPU_MAX_FREQ"
echo "${RESET}"

LOG_DIR="/var/log"
CONFIG_FILE="$INSTALL_DIR/config.sh"
sudo touch "$LOG_DIR/powercontrol.log" "$LOG_DIR/batterycontrol.log" "$LOG_DIR/fancontrol.log"
sudo chmod 644 "$LOG_DIR/powercontrol.log" "$LOG_DIR/batterycontrol.log" "$LOG_DIR/fancontrol.log"
sudo chmod +x /usr/local/bin/.powercontrol_conf.sh
sudo chmod +x /usr/local/bin/.fancontrol_conf.sh
sudo chmod +x /usr/local/bin/.batterycontrol_conf.sh
echo "${YELLOW}Log files for PowerControl, BatteryControl, and FanControl are stored in /var/log/$RESET"
echo ""

USER_HOME="/home/chronos"
echo ""

declare -a ordered_keys=(
  "MAX_TEMP"
  "MAX_PERF_PCT"
  "MIN_TEMP"
  "MIN_PERF_PCT"
  "CHARGE_MAX"
  "CHARGE_MIN"
  "FAN_MIN_TEMP"
  "FAN_MAX_TEMP"
  "MIN_FAN"
  "MAX_FAN"
  "SLEEP_INTERVAL"
  "STEP_UP"
  "STEP_DOWN"
  "GPU_TYPE"
  "GPU_FREQ_PATH"
  "GPU_MAX_FREQ"
  "PERF_PATH"
  "TURBO_PATH"
  "ORIGINAL_GPU_MAX_FREQ"
  "IS_AMD"
  "IS_INTEL"
  "IS_ARM"
)

declare -a ordered_categories=("PowerControl" "BatteryControl" "FanControl" "GPUControl" "Platform Configuration")
declare -A categories=(
  ["PowerControl"]="MAX_TEMP MIN_TEMP MAX_PERF_PCT MIN_PERF_PCT"
  ["BatteryControl"]="CHARGE_MAX CHARGE_MIN"
  ["FanControl"]="MIN_FAN MAX_FAN FAN_MIN_TEMP FAN_MAX_TEMP STEP_UP STEP_DOWN SLEEP_INTERVAL"
  ["GPUControl"]="GPU_MAX_FREQ"
  ["Platform Configuration"]="IS_AMD IS_INTEL IS_ARM PERF_PATH TURBO_PATH GPU_TYPE GPU_FREQ_PATH ORIGINAL_GPU_MAX_FREQ"
)

if [[ -z "${ORIGINAL_GPU_MAX_FREQ}" ]]; then ORIGINAL_GPU_MAX_FREQ=$GPU_MAX_FREQ; fi
if [[ -z "${MAX_TEMP}" ]]; then MAX_TEMP=85; fi
if [[ -z "${MIN_TEMP}" ]]; then MIN_TEMP=60; fi
if [[ -z "${MAX_PERF_PCT}" ]]; then MAX_PERF_PCT=100; fi
if [[ -z "${MIN_PERF_PCT}" ]]; then MIN_PERF_PCT=40; fi
if [[ -z "${CHARGE_MAX}" ]]; then CHARGE_MAX=77; fi
if [[ -z "${CHARGE_MIN}" ]]; then CHARGE_MIN=74; fi
if [[ -z "${MIN_FAN}" ]]; then MIN_FAN=0; fi
if [[ -z "${MAX_FAN}" ]]; then MAX_FAN=100; fi
if [[ -z "${FAN_MIN_TEMP}" ]]; then FAN_MIN_TEMP=46; fi
if [[ -z "${FAN_MAX_TEMP}" ]]; then FAN_MAX_TEMP=80; fi
if [[ -z "${STEP_UP}" ]]; then STEP_UP=20; fi
if [[ -z "${STEP_DOWN}" ]]; then STEP_DOWN=1; fi
if [[ -z "${SLEEP_INTERVAL}" ]]; then SLEEP_INTERVAL=3; fi

declare -A defaults=(
  [MAX_TEMP]=$MAX_TEMP
  [MIN_TEMP]=$MIN_TEMP
  [MAX_PERF_PCT]=$MAX_PERF_PCT
  [MIN_PERF_PCT]=$MIN_PERF_PCT
  [CHARGE_MAX]=$CHARGE_MAX
  [CHARGE_MIN]=$CHARGE_MIN
  [MIN_FAN]=$MIN_FAN
  [MAX_FAN]=$MAX_FAN
  [FAN_MIN_TEMP]=$FAN_MIN_TEMP
  [FAN_MAX_TEMP]=$FAN_MAX_TEMP
  [STEP_UP]=$STEP_UP
  [STEP_DOWN]=$STEP_DOWN
  [SLEEP_INTERVAL]=$SLEEP_INTERVAL
  [GPU_MAX_FREQ]=$GPU_MAX_FREQ
  [GPU_TYPE]=$GPU_TYPE
  [PERF_PATH]=$PERF_PATH
  [TURBO_PATH]=$TURBO_PATH
  [GPU_FREQ_PATH]=$GPU_FREQ_PATH
  [ORIGINAL_GPU_MAX_FREQ]=$GPU_MAX_FREQ
  [IS_AMD]=$IS_AMD
  [IS_INTEL]=$IS_INTEL
  [IS_ARM]=$IS_ARM
)

if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

> "$CONFIG_FILE" 

for category in "${ordered_categories[@]}"; do
  echo "# --- ${category} ---" >> "$CONFIG_FILE"
  for key in ${categories[$category]}; do
        if [ -n "${!key+x}" ]; then
          val="${!key}"
        else
          val="${defaults[$key]}"
        fi
    echo "$key=$val" >> "$CONFIG_FILE"
  done
  echo >> "$CONFIG_FILE"
done

echo "${GREEN}${BOLD}Installing to: $INSTALL_DIR $RESET"

if [ "$IS_INTEL" -eq 1 ]; then
    read -rp "${BOLD}${CYAN}Do you want Intel Turbo Boost disabled on boot? (y/n):$RESET " move_no_turbo
    if [[ "$move_no_turbo" =~ ^[Yy]$ ]]; then
        sudo cp "$INSTALL_DIR/no_turbo.conf" /etc/init/
        echo "Turbo Boost will be disabled on restart."
        echo ""
    else
        echo "Turbo Boost will remain enabled."
        echo ""
    fi
    
    read -rp "${BOLD}${CYAN}Do you want to disable Intel Turbo Boost now? (y/n):$RESET " run_no_turbo
    if [[ "$run_no_turbo" =~ ^[Yy]$ ]]; then
        echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
        echo "Turbo Boost disabled immediately."
        echo ""
    else
        echo "Turbo Boost remains enabled."
        echo ""
    fi
else
    echo "This is not an Intel CPU, skipping Turbo Boost options."
    echo ""
fi

read -rp "${BOLD}${YELLOW}Do you want to create global commands 'powercontrol', 'batterycontrol', 'gpucontrol', and 'fancontrol'? (y/n):$RESET " link_cmd
if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
    sudo ln -sf "$INSTALL_DIR/powercontrol" /usr/local/bin/powercontrol
    sudo ln -sf "$INSTALL_DIR/batterycontrol" /usr/local/bin/batterycontrol
    sudo ln -sf "$INSTALL_DIR/fancontrol" /usr/local/bin/fancontrol
    sudo ln -sf "$INSTALL_DIR/gpucontrol" /usr/local/bin/gpucontrol
    echo "Global commands created for 'powercontrol', 'batterycontrol', 'gpucontrol', and 'fancontrol'."
    echo ""
else
    echo "Skipped creating global commands."
    echo ""
fi
enable_component_on_boot() {
    local component="$1"
    local config_file="$2"
    local var_name="STARTUP_$(echo "$component" | tr '[:lower:]' '[:upper:]')"

    read -rp "${BOLD}${MAGENTA}Do you want $component enabled on boot? (y/n):$RESET " move_config
    if [[ "$move_config" =~ ^[Yy]$ ]]; then
        sudo cp "$config_file" /etc/init/
        echo "$component will start on boot."
        echo "$var_name=1" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo ""
    else
        echo "$component must be started manually on boot."
        echo "$var_name=0" | sudo tee -a "$CONFIG_FILE" > /dev/null
        echo ""
    fi
}


enable_component_on_boot "BatteryControl" "$INSTALL_DIR/batterycontrol.conf"
enable_component_on_boot "PowerControl" "$INSTALL_DIR/powercontrol.conf"
enable_component_on_boot "FanControl" "$INSTALL_DIR/fancontrol.conf"

start_component_now() {
    local component="$1"
    local command="$2"
    read -rp "${BOLD}${GREEN}Do you want to start $component now in the background? (y/n): $RESET " start_now
    if [[ "$start_now" =~ ^[Yy]$ ]]; then
        sudo "$command" start
        echo ""
    else
        echo "You can run it later with: sudo $command start"
        echo ""
    fi
}

start_component_now "BatteryControl" "$INSTALL_DIR/batterycontrol"
start_component_now "PowerControl" "$INSTALL_DIR/powercontrol"
start_component_now "FanControl" "$INSTALL_DIR/fancontrol"

echo ""
echo "           ${RED}████████████${RESET}           "
echo "       ${RED}████${RESET}        ${RED}████${RESET}       "
echo "     ${RED}██${RESET}              ${YELLOW}██${RESET}     "
echo "   ${GREEN}██${RESET}     ${BLUE}██████${RESET}     ${YELLOW}██${RESET}   "
echo "  ${GREEN}██${RESET}     ${BLUE}████████${RESET}     ${YELLOW}██${RESET}  "
echo "  ${GREEN}██${RESET}     ${BLUE}████████${RESET}     ${YELLOW}██${RESET}  "
echo "   ${GREEN}██${RESET}     ${BLUE}██████${RESET}     ${YELLOW}██${RESET}   "
echo "     ${GREEN}██${RESET}              ${YELLOW}██${RESET}     "
echo "       ${GREEN}████${RESET}        ${YELLOW}████${RESET}       "
echo "           ${GREEN}████████████${RESET}           "
echo ""
echo "     ${BOLD}${GREEN}Chrome${RESET}${BOLD}${RED}OS${RESET}${BOLD}${YELLOW}_${RESET}${BOLD}${BLUE}PowerControl${RESET}"
echo ""
echo ""
echo ""
echo "${BOLD}Commands with examples: $RESET"
echo ""
echo "${CYAN}# PowerControl:"
echo "sudo powercontrol                     # Show status"
echo "sudo powercontrol start               # Throttle CPU based on temperature curve"
echo "sudo powercontrol stop                # Restore default CPU settings"
echo "sudo powercontrol no_turbo 1          # 0 = Enable, 1 = Disable Turbo Boost"
echo "sudo powercontrol max_perf_pct 75     # Set max performance percentage"
echo "sudo powercontrol min_perf_pct 50     # Set minimum performance at max temp"
echo "sudo powercontrol max_temp 86         # Max temperature threshold - Limit is 90 C"
echo "sudo powercontrol min_temp 60         # Min temperature threshold"
echo "sudo powercontrol monitor             # Toggle live temperature monitoring"
echo "sudo powercontrol startup             # Copy or Remove no_turbo.conf & powercontrol.conf at: /etc/init/"
echo "sudo powercontrol help                # Help menu"
echo "$RESET"
echo "${GREEN}# BatteryControl:"
echo "sudo batterycontrol                   # Check BatteryControl status"
echo "sudo batterycontrol start             # Start BatteryControl"
echo "sudo batterycontrol stop              # Stop BatteryControl"
echo "sudo batterycontrol set 77 74         # Set max/min battery charge thresholds"
echo "sudo batterycontrol startup           # Copy or Remove batterycontrol.conf at: /etc/init/"
echo "sudo batterycontrol help              # Help menu"
echo "$RESET"
echo "${YELLOW}# FanControl:"
echo "sudo fancontrol                       # Show FanControl status"
echo "sudo fancontrol start                 # Start FanControl"
echo "sudo fancontrol stop                  # Stop FanControl"
echo "sudo fancontrol fan_min_temp 48       # Min temp threshold"
echo "sudo fancontrol fan_max_temp 81       # Max temp threshold - Limit is 90 C"
echo "sudo fancontrol min_fan 0             # Min fan speed %"
echo "sudo fancontrol max_fan 100           # Max fan speed %"
echo "sudo fancontrol stepup 20             # Fan step-up %"
echo "sudo fancontrol stepdown 1            # Fan step-down %"
echo "sudo fancontrol startup               # Copy or Remove fancontrol.conf at: /etc/init/"
echo "sudo fancontrol help                  # Help menu"
echo "$RESET"
echo "${MAGENTA}# GPUControl:"
echo "sudo gpucontrol                       # Show current GPU info and frequency"
echo "sudo gpucontrol restore               # Restore GPU max frequency to original value"
echo "sudo gpucontrol intel 700             # Set Intel GPU max frequency to 700 MHz"
echo "sudo gpucontrol amd 800               # Set AMD GPU max frequency to 800 MHz (rounds to nearest dpm)"
echo "sudo gpucontrol amd auto              # Restores AMD GPU behavior. Altering clock speeds above will switch it to manual"
echo "sudo gpucontrol adreno 500000         # Set Adreno GPU max frequency to 500000 kHz (or 500 MHz)"
echo "sudo gpucontrol mali 600000           # Set Mali GPU max frequency to 600000 kHz (or 600 MHz)${RESET}"
echo ""
echo "${BLUE}sudo powercontrol uninstall           # Run uninstaller"
echo "Alternative:"
echo "sudo bash "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh" $RESET"
echo ""
