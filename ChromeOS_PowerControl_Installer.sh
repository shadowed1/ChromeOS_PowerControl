#!/bin/bash

sudo mkdir -p /usr/local/bin/ChromeOS_PowerControl
echo "Enabling sudo in crosh or run in VT-2 is required!"

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

sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/powercontrol
sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/batterycontrol
sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh

# Use the invoking user's home directory, even when running with sudo
USER_HOME=$(eval echo "~$SUDO_USER")

BATTERY_CONFIG="$USER_HOME/.batterycontrol_config"
BATTERY_RUN_FLAG="$USER_HOME/.batterycontrol_enabled"

if [ ! -f "$BATTERY_CONFIG" ]; then
    echo "CHARGE_MAX=77" > "$BATTERY_CONFIG"
    echo "CHARGE_MIN=74" >> "$BATTERY_CONFIG"
    echo "Default batterycontrol config created at $BATTERY_CONFIG"
else
    echo "BatteryControl config file already exists at $BATTERY_CONFIG"
fi

if [ ! -f "$BATTERY_RUN_FLAG" ]; then
    touch "$BATTERY_RUN_FLAG"
    echo "BatteryControl enabled flag created at $BATTERY_RUN_FLAG"
fi

POWER_CONFIG="$USER_HOME/.powercontrol_config"
POWER_RUN_FLAG="$USER_HOME/.powercontrol_enabled"

if [ ! -f "$POWER_CONFIG" ]; then
    echo "MAX_TEMP_K=358" > "$POWER_CONFIG"    # 85°C in Kelvin
    echo "MAX_PERF_PCT=85" >> "$POWER_CONFIG" # Default max performance %
    echo "Default powercontrol config created at $POWER_CONFIG"
else
    echo "PowerControl config file already exists at $POWER_CONFIG"
fi

if [ ! -f "$POWER_RUN_FLAG" ]; then
    touch "$POWER_RUN_FLAG"
    echo "PowerControl enabled flag created at $POWER_RUN_FLAG"
fi

read -rp "Do you want Intel Turbo Boost disabled on boot? (y/n): " move_no_turbo
if [[ "$move_no_turbo" =~ ^[Yy]$ ]]; then
    sudo mv /usr/local/bin/ChromeOS_PowerControl/no_turbo.conf /etc/init/
    echo "Turbo Boost will be disabled on restart."
else
    echo "Turbo Boost will be enabled on restart."
fi

read -rp "Do you want to disable Intel Turbo Boost now? (y/n): " run_no_turbo
if [[ "$run_no_turbo" =~ ^[Yy]$ ]]; then
    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
else
    echo "Turbo Boost will remain enabled."
fi

read -rp "Do you want to create a global command 'powercontrol' for faster changes? (y/n): " link_cmd
if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
    sudo ln -sf /usr/local/bin/ChromeOS_PowerControl/powercontrol /usr/local/bin/powercontrol
    echo "'powercontrol' command is now available system-wide."
else
    echo "Skipped creating global command."
fi

read -rp "Do you want to create a global command 'batterycontrol' for faster changes? (y/n): " link_cmd
if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
    sudo ln -sf /usr/local/bin/ChromeOS_PowerControl/batterycontrol /usr/local/bin/batterycontrol
    echo "'batterycontrol' command is now available system-wide."
else
    echo "Skipped creating global command."
fi
