#!/bin/bash

detect_cpu_type() {
    CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || echo "unknown")
    
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
    
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        echo "Creating default configuration..."
        STARTUP_BATTERYCONTROL=1
        STARTUP_FANCONTROL=1
        STARTUP_POWERCONTROL=1
        save_config
    fi
}

save_config() {
    echo "Saving configuration..."
    echo "STARTUP_BATTERYCONTROL=$STARTUP_BATTERYCONTROL" > "$CONFIG_FILE"
    echo "STARTUP_FANCONTROL=$STARTUP_FANCONTROL" >> "$CONFIG_FILE"
    echo "STARTUP_POWERCONTROL=$STARTUP_POWERCONTROL" >> "$CONFIG_FILE"
    echo "CHARGE_MAX=77" >> "$CONFIG_FILE"
    echo "CHARGE_MIN=74" >> "$CONFIG_FILE"
    echo "MAX_TEMP=86" >> "$CONFIG_FILE"
    echo "MAX_PERF_PCT=100" >> "$CONFIG_FILE"
    echo "MIN_TEMP=60" >> "$CONFIG_FILE"
    echo "MIN_PERF_PCT=50" >> "$CONFIG_FILE"
    echo "FAN_MIN_TEMP=48" >> "$CONFIG_FILE"
    echo "FAN_MAX_TEMP=81" >> "$CONFIG_FILE"
    echo "FAN_MIN=0" >> "$CONFIG_FILE"
    echo "FAN_MAX=100" >> "$CONFIG_FILE"
    echo "FAN_SLEEP_INTERVAL=3" >> "$CONFIG_FILE"
    echo "FAN_STEP_UP=20" >> "$CONFIG_FILE"
    echo "FAN_STEP_DOWN=1" >> "$CONFIG_FILE"
    echo "PERF_PATH=$PERF_PATH" >> "$CONFIG_FILE"
    echo "TURBO_PATH=$TURBO_PATH" >> "$CONFIG_FILE"
    echo "IS_AMD=$IS_AMD" >> "$CONFIG_FILE"
    echo "IS_INTEL=$IS_INTEL" >> "$CONFIG_FILE"
    echo "IS_ARM=$IS_ARM" >> "$CONFIG_FILE"
}

enable_component_on_boot() {
    local component="$1"
    read -rp "Do you want $component enabled on boot? (y/n): " enable_boot
    if [[ "$enable_boot" =~ ^[Yy]$ ]]; then
        echo "$component will start on boot."
        # Enable in config
        case $component in
            "BatteryControl")
                STARTUP_BATTERYCONTROL=1
                ;;
            "FanControl")
                STARTUP_FANCONTROL=1
                ;;
            "PowerControl")
                STARTUP_POWERCONTROL=1
                ;;
        esac
    else
        echo "$component will not start on boot."
        case $component in
            "BatteryControl")
                STARTUP_BATTERYCONTROL=0
                ;;
            "FanControl")
                STARTUP_FANCONTROL=0
                ;;
            "PowerControl")
                STARTUP_POWERCONTROL=0
                ;;
        esac
    fi
    save_config
}

detect_cpu_type
echo "Detected CPU Vendor: $CPU_VENDOR"
echo "PERF_PATH: $PERF_PATH"
echo "TURBO_PATH: $TURBO_PATH"

read -rp "Enter Install Path - leave blank for: /usr/local/bin/ChromeOS_PowerControl: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin/ChromeOS_PowerControl}"
INSTALL_DIR="${INSTALL_DIR%/}"
echo "$INSTALL_DIR" | sudo tee /usr/local/bin/ChromeOS_PowerControl.install_dir > /dev/null
echo ""

echo "Installing to: $INSTALL_DIR"
echo ""
sudo mkdir -p "$INSTALL_DIR"
declare -a files=("powercontrol" "batterycontrol" "fancontrol" "Uninstall_ChromeOS_PowerControl.sh" "LICENSE" "README.md" "no_turbo.conf" "batterycontrol.conf" "powercontrol.conf" "fancontrol.conf" "config.sh")
for file in "${files[@]}"; do
    curl -L "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/$file" -o "$INSTALL_DIR/$file"
    echo "$INSTALL_DIR/$file downloaded."
    echo ""
done

# Load configuration (or create a new one)
CONFIG_FILE="$INSTALL_DIR/config.sh"
load_config

enable_component_on_boot "BatteryControl"
echo ""
enable_component_on_boot "FanControl"
echo ""
enable_component_on_boot "PowerControl"
echo ""

read -rp "Do you want to create global commands 'powercontrol', 'batterycontrol', and 'fancontrol'? (y/n): " link_cmd
if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
    sudo ln -sf "$INSTALL_DIR/powercontrol" /usr/local/bin/powercontrol
    sudo ln -sf "$INSTALL_DIR/batterycontrol" /usr/local/bin/batterycontrol
    sudo ln -sf "$INSTALL_DIR/fancontrol" /usr/local/bin/fancontrol
    echo "Global commands created for 'powercontrol', 'batterycontrol', and 'fancontrol'."
    echo ""
else
    echo "Skipped creating global commands."
fi

start_component_now() {
    local component="$1"
    local command="$2"
    read -rp "Do you want to start $component now in the background? (y/n): " start_now
    if [[ "$start_now" =~ ^[Yy]$ ]]; then
        sudo "$command" start
        echo "$component started in the background."
        echo ""
    else
        echo "You can run it later with: sudo $command start"
    fi
}

start_component_now "BatteryControl" "$INSTALL_DIR/batterycontrol"
echo ""
start_component_now "PowerControl" "$INSTALL_DIR/powercontrol"
echo ""
start_component_now "FanControl" "$INSTALL_DIR/fancontrol"
echo ""


echo ""
echo "Commands with examples:"
echo ""
echo "# PowerControl Commands:"
echo "sudo powercontrol                     # Show status"
echo "sudo powercontrol start               # Throttle CPU based on temperature curve"
echo "sudo powercontrol stop                # Restore default CPU settings"
echo "sudo powercontrol no_turbo 1          # Disable turbo boost"
echo "sudo powercontrol max_perf_pct 75     # Set max performance percentage"
echo "sudo powercontrol min_perf_pct 50     # Set minimum performance at max temp"
echo "sudo powercontrol max_temp 86         # Max temperature threshold"
echo "sudo powercontrol min_temp 60         # Min temperature threshold"
echo "sudo powercontrol monitor             # Live temperature monitoring"
echo "sudo powercontrol startup 1           # Toggle 1 (on) 0 (off) for starting on boot."
echo "sudo powercontrol help                # Help menu"
echo ""
echo "# BatteryControl Commands:"
echo "sudo batterycontrol start             # Start BatteryControl"
echo "sudo batterycontrol stop              # Stop BatteryControl"
echo "sudo batterycontrol status            # Check BatteryControl status"
echo "sudo batterycontrol set 80 75         # Set max/min battery charge thresholds"
echo "sudo batterycontrol startup 1         # Toggle 1 (on) 0 (off) for starting on boot."
echo "sudo batterycontrol help              # Help menu"
echo ""
echo "# FanControl Commands:"
echo "sudo fancontrol                       # Show fan status"
echo "sudo fancontrol start                 # Start FanControl"
echo "sudo fancontrol stop                  # Stop FanControl"
echo "sudo fancontrol fan_min_temp 50       # Min temp threshold"
echo "sudo fancontrol fan_max_temp 90       # Max temp threshold"
echo "sudo fancontrol min_fan 0             # Min fan speed %"
echo "sudo fancontrol max_fan 100           # Max fan speed %"
echo "sudo fancontrol stepup 20             # Fan step-up %"
echo "sudo fancontrol stepdown 1            # Fan step-down %" 
echo "sudo fancontrol startup 1             # Toggle 1 (on) 0 (off) for starting on boot."
echo "sudo fancontrol help                  # Help menu"
echo ""
echo "sudo powercontrol uninstall           # Run uninstaller"
echo "Alternative: sudo bash "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh" "
