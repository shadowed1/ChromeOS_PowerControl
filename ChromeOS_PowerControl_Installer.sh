#!/bin/bash

# Create the necessary directory for installation
sudo mkdir -p /usr/local/bin/ChromeOS_PowerControl
echo "Enabling sudo in crosh or run in VT-2 is required for this to download successfully."
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/powercontrol -o /usr/local/bin/ChromeOS_PowerControl/powercontrol
echo " /usr/local/bin/ChromeOS_PowerControl/powercontrol downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/batterycontrol -o /usr/local/bin/ChromeOS_PowerControl/batterycontrol
echo " /usr/local/bin/ChromeOS_PowerControl/batterycontrol downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/Uninstall_ChromeOS_PowerControl.sh -o /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh
echo " /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/LICENSE -o /usr/local/bin/ChromeOS_PowerControl/LICENSE
echo " /usr/local/bin/ChromeOS_PowerControl/LICENSE downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/README.md -o /usr/local/bin/ChromeOS_PowerControl/README.md
echo " /usr/local/bin/ChromeOS_PowerControl/README.md downloaded."

curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/no_turbo.conf -o /usr/local/bin/ChromeOS_PowerControl/no_turbo.conf
echo " /usr/local/bin/ChromeOS_PowerControl/no_turbo.conf downloaded."
echo ""

sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/powercontrol
sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/batterycontrol
sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh
sudo touch /usr/local/bin/ChromeOS_PowerControl/.batterycontrol_enabled
sudo touch /usr/local/bin/ChromeOS_PowerControl/.powercontrol_enabled
echo " /usr/local/bin/ChromeOS_PowerControl/.batterycontrol_enabled created."
echo ""
echo " /usr/local/bin/ChromeOS_PowerControl/.powercontrol_enabled created."
echo ""

# Use the invoking user's home directory, which should be /home/chronos
USER_HOME="/home/chronos"

# Battery control files location
BATTERY_CONFIG="/usr/local/bin/ChromeOS_PowerControl/.batterycontrol_config"
BATTERY_RUN_FLAG="/usr/local/bin/ChromeOS_PowerControl/.batterycontrol_enabled"

# Create battery control config if not already present
if [ ! -f "$BATTERY_CONFIG" ]; then
    echo "CHARGE_MAX=77" > "$BATTERY_CONFIG"
    echo "CHARGE_MIN=74" >> "$BATTERY_CONFIG"
    echo "/usr/local/bin/ChromeOS_PowerControl/batterycontrol config created"
    echo ""
else
    echo "BatteryControl config file already exists at $BATTERY_CONFIG"
fi

# Create battery run flag if not already present
if [ ! -f "$BATTERY_RUN_FLAG" ]; then
    touch "$BATTERY_RUN_FLAG"
    echo "BatteryControl enabled flag created at $BATTERY_RUN_FLAG"
fi

# Power control files location
POWER_CONFIG="/usr/local/bin/ChromeOS_PowerControl/.powercontrol_config"
POWER_RUN_FLAG="/usr/local/bin/ChromeOS_PowerControl/.powercontrol_enabled"

# Create power control config if not already present
load_config() {
    if [ -f "$POWER_CONFIG" ]; then
        source "$POWER_CONFIG"
    else
        MAX_TEMP=$DEFAULT_MAX_TEMP
        MAX_PERF_PCT=$DEFAULT_MAX_PERF_PCT
        MIN_TEMP=$DEFAULT_MIN_TEMP
        MIN_PERF_PCT=$DEFAULT_MIN_PERF_PCT
        save_config
    fi
}
# Create power run flag if not already present
if [ ! -f "$POWER_RUN_FLAG" ]; then
    touch "$POWER_RUN_FLAG"
    echo "PowerControl enabled flag created at $POWER_RUN_FLAG"
fi

# Disable Intel Turbo Boost on boot option
read -rp "Do you want Intel Turbo Boost disabled on boot? (y/n): " move_no_turbo
echo ""
if [[ "$move_no_turbo" =~ ^[Yy]$ ]]; then
    sudo mv /usr/local/bin/ChromeOS_PowerControl/no_turbo.conf /etc/init/
    echo "Turbo Boost will be disabled on restart."
    echo ""
else
    echo "Turbo Boost will be enabled on restart."
fi

# Disable Intel Turbo Boost now option
read -rp "Do you want to disable Intel Turbo Boost now? (y/n): " run_no_turbo
echo ""
if [[ "$run_no_turbo" =~ ^[Yy]$ ]]; then
    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
else
    echo "Turbo Boost will remain enabled."
    echo ""
fi

# Create global commands for 'powercontrol' and 'batterycontrol'
read -rp "Do you want to create global commands 'powercontrol' and 'batterycontrol' for faster changes? (y/n): " link_cmd
echo ""

if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
    # Create powercontrol command
    sudo ln -sf /usr/local/bin/ChromeOS_PowerControl/powercontrol /usr/local/bin/powercontrol
    echo "'powercontrol' command is now available system-wide."
    echo ""

    # Create batterycontrol command
    sudo ln -sf /usr/local/bin/ChromeOS_PowerControl/batterycontrol /usr/local/bin/batterycontrol
    echo "'batterycontrol' command is now available system-wide."
    echo ""
else
    echo "Skipped creating global commands."
    echo ""
fi


# Final message
echo "Examples:"
echo "sudo powercontrol start               # Throttle CPU based on temperature"
echo "sudo powercontrol stop                # Default CPU temperature curve"
echo "sudo powercontrol no_turbo 1          # 0 is default Intel Turbo Boost On behavior."
echo "sudo powercontrol max_perf_pct 75     # 100 is default behavior; can be run standalone."
echo "sudo powercontrol min_perf_pct 50     # Minimum clockspeed CPU can reach at max_temp."
echo "echo sudo powercontrol max_temp       # Controls the lower clockspeed part of the curve."
echo "sudo powercontrol min_temp            # Controls the higher clockspeed part of the curve."
echo "sudo powercontrol help"
echo""
echo "sudo batterycontrol start               # starts batterycontrol"
echo "sudo batterycontrol stop                # stops batterycontrol"
echo "sudo batterycontrol status              # shows status"
echo "sudo batterycontrol set 80 75           # 80 is when charging stops; 75 is when charging may begin"
echo "sudo batterycontrol help"
echo ""
echo "sudo powercontrol uninstall            # Global uninstaller"
echo "Alternative uninstall method:"
echo "sudo /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh"
