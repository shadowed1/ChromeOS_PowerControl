#!/bin/bash

# Function to detect CPU type
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
}

# Function to load configuration settings
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

# Function to save configuration settings
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

# Function to prompt user for enabling components at startup
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
        # Disable in config
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

# Main script logic
detect_cpu_type
echo "Detected CPU Vendor: $CPU_VENDOR"
echo "PERF_PATH: $PERF_PATH"
echo "TURBO_PATH: $TURBO_PATH"

# Prompt for install directory
read -rp "Enter Install Path - leave blank for: /usr/local/bin/ChromeOS_PowerControl: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin/ChromeOS_PowerControl}"
INSTALL_DIR="${INSTALL_DIR%/}"
echo "$INSTALL_DIR" | sudo tee usr/local/bin/ChromeOS_PowerControl.install_dir > /dev/null

# Create install directory and download necessary files
echo "Installing to: $INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
declare -a files=("powercontrol" "batterycontrol" "fancontrol" "Uninstall_ChromeOS_PowerControl.sh" "LICENSE" "README.md" "no_turbo.conf" "batterycontrol.conf" "powercontrol.conf" "fancontrol.conf" "config.sh")
for file in "${files[@]}"; do
    curl -L "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/$file" -o "$INSTALL_DIR/$file"
    echo "$INSTALL_DIR/$file downloaded."
done

# Load configuration (or create a new one)
CONFIG_FILE="$INSTALL_DIR/config.sh"
load_config

# Enable components on boot
enable_component_on_boot "BatteryControl"
enable_component_on_boot "FanControl"
enable_component_on_boot "PowerControl"

# Ask the user if they want to link global commands
read -rp "Do you want to create global commands 'powercontrol', 'batterycontrol', and 'fancontrol'? (y/n): " link_cmd
if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
    sudo ln -sf "$INSTALL_DIR/powercontrol" /usr/local/bin/powercontrol
    sudo ln -sf "$INSTALL_DIR/batterycontrol" /usr/local/bin/batterycontrol
    sudo ln -sf "$INSTALL_DIR/fancontrol" /usr/local/bin/fancontrol
    echo "Global commands created for 'powercontrol', 'batterycontrol', and 'fancontrol'."
else
    echo "Skipped creating global commands."
fi

# Start components now (optional)
start_component_now() {
    local component="$1"
    local command="$2"
    read -rp "Do you want to start $component now in the background? (y/n): " start_now
    if [[ "$start_now" =~ ^[Yy]$ ]]; then
        sudo "$command" start
        echo "$component started in the background."
    else
        echo "You can run it later with: sudo $command start"
    fi
}

start_component_now "BatteryControl" "$INSTALL_DIR/batterycontrol"
start_component_now "PowerControl" "$INSTALL_DIR/powercontrol"
start_component_now "FanControl" "$INSTALL_DIR/fancontrol"

