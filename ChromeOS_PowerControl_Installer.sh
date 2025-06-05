#!/bin/bash

read -rp "Enter Install Path - leave blank for: /usr/local/bin/ChromeOS_PowerControl: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin/ChromeOS_PowerControl}"

echo "Installing to: $INSTALL_DIR"
echo ""
sudo mkdir -p "$INSTALL_DIR"
echo "Enabling sudo in crosh or run in VT-2 is required for this to download successfully."

# Download required files
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/powercontrol -o "$INSTALL_DIR/powercontrol"
echo "$INSTALL_DIR/powercontrol downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/batterycontrol -o "$INSTALL_DIR/batterycontrol"
echo "$INSTALL_DIR/batterycontrol downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/fancontrol -o "$INSTALL_DIR/fancontrol"
echo "$INSTALL_DIR/fancontrol downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/Uninstall_ChromeOS_PowerControl.sh -o "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh"
echo "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/LICENSE -o "$INSTALL_DIR/LICENSE"
echo "$INSTALL_DIR/LICENSE downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/README.md -o "$INSTALL_DIR/README.md"
echo "$INSTALL_DIR/README.md downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/no_turbo.conf -o "$INSTALL_DIR/no_turbo.conf"
echo "$INSTALL_DIR/no_turbo.conf downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/batterycontrol.conf -o "$INSTALL_DIR/batterycontrol.conf"
echo "$INSTALL_DIR/batterycontrol.conf downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/powercontrol.conf -o "$INSTALL_DIR/powercontrol.conf"
echo "$INSTALL_DIR/powercontrol.conf downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/fancontrol.conf -o "$INSTALL_DIR/fancontrol.conf"
echo "$INSTALL_DIR/fancontrol.conf downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/config.sh -o "$INSTALL_DIR/config.sh"
echo "$INSTALL_DIR/config.sh downloaded."

sudo chmod +x "$INSTALL_DIR/powercontrol" "$INSTALL_DIR/batterycontrol" "$INSTALL_DIR/fancontrol" "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh"

sudo touch "$INSTALL_DIR/.batterycontrol_enabled" "$INSTALL_DIR/.powercontrol_enabled" "$INSTALL_DIR/.fancontrol_enabled"
echo "Flag files created for BatteryControl, PowerControl, and FanControl."

sudo touch /var/log/powercontrol.log /var/log/batterycontrol.log /var/log/fancontrol.log
echo "Log files created for PowerControl, BatteryControl, and FanControl."

USER_HOME="/home/chronos"
BATTERY_CONFIG="$INSTALL_DIR/.batterycontrol_config"
POWER_CONFIG="$INSTALL_DIR/.powercontrol_config"
FAN_CONFIG="$INSTALL_DIR/.fancontrol_config"

if [ ! -f "$BATTERY_CONFIG" ]; then
    echo "CHARGE_MAX=77" > "$BATTERY_CONFIG"
    echo "CHARGE_MIN=74" >> "$BATTERY_CONFIG"
    echo "BatteryControl config created at $BATTERY_CONFIG"
else
    echo "BatteryControl config file already exists at $BATTERY_CONFIG"
fi

load_power_config() {
    if [ -f "$POWER_CONFIG" ]; then
        source "$POWER_CONFIG"
    else
        echo "MAX_TEMP=86" > "$POWER_CONFIG"
        echo "MAX_PERF_PCT=100" >> "$POWER_CONFIG"
        echo "MIN_TEMP=60" >> "$POWER_CONFIG"
        echo "MIN_PERF_PCT=50" >> "$POWER_CONFIG"
        echo "PowerControl config created at $POWER_CONFIG"
    fi
}

load_power_config

load_fan_config() {
    if [ -f "$FAN_CONFIG" ]; then
        source "$FAN_CONFIG"
    else
        echo "MIN_TEMP=48" > "$FAN_CONFIG"
        echo "MAX_TEMP=81" >> "$FAN_CONFIG"
        echo "MIN_FAN=0" >> "$FAN_CONFIG"
        echo "MAX_FAN=100" >> "$FAN_CONFIG"
        echo "SLEEP_INTERVAL=3" >> "$FAN_CONFIG"
        echo "FanControl config created at $FAN_CONFIG"
    fi
}

load_fan_config

read -rp "Do you want Intel Turbo Boost disabled on boot? Requires removing rootfs verification. (y/n): " move_no_turbo
if [[ "$move_no_turbo" =~ ^[Yy]$ ]]; then
    sudo mv "$INSTALL_DIR/no_turbo.conf" /etc/init/
    echo "Turbo Boost will be disabled on restart."
else
    echo "Turbo Boost will remain enabled."
fi

read -rp "Do you want to disable Intel Turbo Boost now? (y/n): " run_no_turbo
if [[ "$run_no_turbo" =~ ^[Yy]$ ]]; then
    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
    echo "Turbo Boost disabled immediately."
else
    echo "Turbo Boost remains enabled."
fi

read -rp "Do you want to create global commands 'powercontrol', 'batterycontrol', and 'fancontrol'? (y/n): " link_cmd
if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
    sudo ln -sf "$INSTALL_DIR/powercontrol" /usr/local/bin/powercontrol
    sudo ln -sf "$INSTALL_DIR/batterycontrol" /usr/local/bin/batterycontrol
    sudo ln -sf "$INSTALL_DIR/fancontrol" /usr/local/bin/fancontrol
    echo "Global commands created for 'powercontrol', 'batterycontrol', and 'fancontrol'."
else
    echo "Skipped creating global commands."
fi

enable_component_on_boot() {
    local component="$1"
    local config_file="$2"
    read -rp "Do you want $component enabled on boot? (y/n): " move_config
    if [[ "$move_config" =~ ^[Yy]$ ]]; then
        sudo mv "$config_file" /etc/init/
        echo "$component will start on boot."
    else
        echo "$component must be started manually on boot."
    fi
}

enable_component_on_boot "BatteryControl" "$INSTALL_DIR/batterycontrol.conf"
enable_component_on_boot "PowerControl" "$INSTALL_DIR/powercontrol.conf"
enable_component_on_boot "FanControl" "$INSTALL_DIR/fancontrol.conf"

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

echo ""
echo "Commands with examples:"
cat << EOF
# PowerControl Commands:
sudo powercontrol                     # Show status
sudo powercontrol start               # Throttle CPU based on temperature curve
sudo powercontrol stop                # Restore default CPU settings
sudo powercontrol no_turbo 1          # Disable turbo boost
sudo powercontrol max_perf_pct 75     # Set max performance percentage
sudo powercontrol min_perf_pct 50     # Set minimum performance at max temp
sudo powercontrol max_temp 86         # Max temperature threshold
sudo powercontrol min_temp 60         # Min temperature threshold
sudo powercontrol monitor             # Live temperature monitoring
sudo powercontrol help                # Help menu

# BatteryControl Commands:
sudo batterycontrol start             # Start BatteryControl
sudo batterycontrol stop              # Stop BatteryControl
sudo batterycontrol status            # Check BatteryControl status
sudo batterycontrol set 80 75         # Set max/min battery charge thresholds
sudo batterycontrol help              # Help menu

# FanControl Commands:
sudo fancontrol                       # Show fan status
sudo fancontrol start                 # Start FanControl
sudo fancontrol stop                  # Stop FanControl
sudo fancontrol min_temp 50           # Min temp threshold
sudo fancontrol max_temp 90           # Max temp threshold
sudo fancontrol min_fan 0             # Min fan speed %
sudo fancontrol max_fan 100           # Max fan speed %
sudo fancontrol stepup 20             # Fan step-up %
sudo fancontrol stepdown 1            # Fan step-down %
sudo fancontrol help                  # Help menu

sudo powercontrol uninstall           # Run uninstaller
Alternative: sudo bash "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh"

EOF
