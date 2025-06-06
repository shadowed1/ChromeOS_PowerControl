#!/bin/bash

sudo mkdir -p /usr/local/bin/ChromeOS_PowerControl
echo ""
echo "Enabling sudo in crosh or run in VT-2 is required for this to download successfully."
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/powercontrol -o /usr/local/bin/ChromeOS_PowerControl/powercontrol
echo " /usr/local/bin/ChromeOS_PowerControl/powercontrol downloaded."
echo ""
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/batterycontrol -o /usr/local/bin/ChromeOS_PowerControl/batterycontrol
echo " /usr/local/bin/ChromeOS_PowerControl/batterycontrol downloaded."
echo ""
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/fancontrol -o /usr/local/bin/ChromeOS_PowerControl/fancontrol
echo " /usr/local/bin/ChromeOS_PowerControl/fancontrol downloaded."
echo ""
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/Uninstall_ChromeOS_PowerControl.sh -o /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh
echo " /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh downloaded."
echo ""
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/LICENSE -o /usr/local/bin/ChromeOS_PowerControl/LICENSE
echo " /usr/local/bin/ChromeOS_PowerControl/LICENSE downloaded."
echo ""
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/README.md -o /usr/local/bin/ChromeOS_PowerControl/README.md
echo " /usr/local/bin/ChromeOS_PowerControl/README.md downloaded."
echo ""
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/no_turbo.conf -o /usr/local/bin/ChromeOS_PowerControl/no_turbo.conf
echo " /usr/local/bin/ChromeOS_PowerControl/no_turbo.conf downloaded."
echo ""
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/batterycontrol.conf -o /usr/local/bin/ChromeOS_PowerControl/batterycontrol.conf
echo " /usr/local/bin/ChromeOS_PowerControl/batterycontrol.conf downloaded."
echo ""
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/powercontrol.conf -o /usr/local/bin/ChromeOS_PowerControl/powercontrol.conf
echo " /usr/local/bin/ChromeOS_PowerControl/powercontrol.conf downloaded."
echo ""
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/fancontrol.conf -o /usr/local/bin/ChromeOS_PowerControl/fancontrol.conf
echo " /usr/local/bin/ChromeOS_PowerControl/fancontrol.conf downloaded."
echo ""

sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/powercontrol
sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/batterycontrol
sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/fancontrol
sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh
sudo touch /usr/local/bin/ChromeOS_PowerControl/.batterycontrol_enabled
sudo touch /usr/local/bin/ChromeOS_PowerControl/.powercontrol_enabled
sudo touch /usr/local/bin/ChromeOS_PowerControl/.fancontrol_enabled
echo " /usr/local/bin/ChromeOS_PowerControl/.batterycontrol_enabled created."
echo ""
echo " /usr/local/bin/ChromeOS_PowerControl/.powercontrol_enabled created."
echo ""
echo " /usr/local/bin/ChromeOS_PowerControl/.fancontrol_enabled created."
echo ""
sudo touch /usr/local/bin/ChromeOS_PowerControl/powercontrol.log
sudo touch /usr/local/bin/ChromeOS_PowerControl/batterycontrol.log
sudo touch /usr/local/bin/ChromeOS_PowerControl/fancontrol.log
echo " /usr/local/bin/ChromeOS_PowerControl/batterycontrol.log created."
echo ""
echo " /usr/local/bin/ChromeOS_PowerControl/powercontrol.log created."
echo ""
echo " /usr/local/bin/ChromeOS_PowerControl/fancontrol.log created."
echo ""

USER_HOME="/home/chronos"

BATTERY_CONFIG="/usr/local/bin/ChromeOS_PowerControl/.batterycontrol_config"
BATTERY_RUN_FLAG="/usr/local/bin/ChromeOS_PowerControl/.batterycontrol_enabled"

if [ ! -f "$BATTERY_CONFIG" ]; then
    echo "CHARGE_MAX=77" > "$BATTERY_CONFIG"
    echo "CHARGE_MIN=74" >> "$BATTERY_CONFIG"
    echo "/usr/local/bin/ChromeOS_PowerControl/batterycontrol config created"
    echo ""
else
    echo "BatteryControl config file already exists at $BATTERY_CONFIG"
fi

if [ ! -f "$BATTERY_RUN_FLAG" ]; then
    touch "$BATTERY_RUN_FLAG"
    echo "BatteryControl enabled flag created at $BATTERY_RUN_FLAG"
fi

POWER_CONFIG="/usr/local/bin/ChromeOS_PowerControl/.powercontrol_config"
POWER_RUN_FLAG="/usr/local/bin/ChromeOS_PowerControl/.powercontrol_enabled"

load_power_config() {
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

if [ ! -f "$POWER_RUN_FLAG" ]; then
    touch "$POWER_RUN_FLAG"
    echo "PowerControl enabled flag created at $POWER_RUN_FLAG"
fi

FAN_CONFIG="/usr/local/bin/ChromeOS_PowerControl/.fancontrol_config"
FAN_RUN_FLAG="/usr/local/bin/ChromeOS_PowerControl/.fancontrol_enabled"

load_fan_config() {
    if [ -f "$FAN_CONFIG" ]; then
        source "$FAN_CONFIG"
    else
        MIN_TEMP=$DEFAULT_MIN_TEMP
        MAX_TEMP=$DEFAULT_MAX_TEMP
        MIN_FAN=$DEFAULT_MIN_FAN
        MAX_FAN=$DEFAULT_MAX_FAN
        SLEEP_INTERVAL=$DEFAULT_SLEEP_INTERVAL
        STEP_SIZE=$DEFAULT_STEP_SIZE
        save_config
    fi
}

if [ ! -f "$FAN_RUN_FLAG" ]; then
    touch "$FAN_RUN_FLAG"
    echo "FanControl enabled flag created at $FAN_RUN_FLAG"
fi

read -rp "Do you want Intel Turbo Boost disabled on boot? Requires removing rootfs verification. (y/n): " move_no_turbo
echo ""
if [[ "$move_no_turbo" =~ ^[Yy]$ ]]; then
    sudo mv /usr/local/bin/ChromeOS_PowerControl/no_turbo.conf /etc/init/
    echo "Turbo Boost will be disabled on restart."
    echo ""
else
    echo "Turbo Boost will be enabled on restart."
fi

read -rp "Do you want to disable Intel Turbo Boost now? (y/n): " run_no_turbo
echo ""
if [[ "$run_no_turbo" =~ ^[Yy]$ ]]; then
    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
else
    echo "Turbo Boost will remain enabled."
    echo ""
fi

read -rp "Do you want to create global commands 'powercontrol', 'batterycontrol' and 'fancontrol'? for faster changes? (y/n): " link_cmd
echo ""

if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
    sudo ln -sf /usr/local/bin/ChromeOS_PowerControl/powercontrol /usr/local/bin/powercontrol
    echo "'powercontrol' command is now available system-wide."
    echo ""

    sudo ln -sf /usr/local/bin/ChromeOS_PowerControl/batterycontrol /usr/local/bin/batterycontrol
    echo "'batterycontrol' command is now available system-wide."
    echo ""

    sudo ln -sf /usr/local/bin/ChromeOS_PowerControl/fancontrol /usr/local/bin/fancontrol
    echo "'fancontrol' command is now available system-wide."
    echo ""
else
    echo "Skipped creating global commands."
    echo ""
fi

read -rp "Do you want BatteryControl enabled on boot? Requires removing rootfs verification. (y/n): " move_batterycontrolconf
echo ""
if [[ "$move_batterycontrolconf" =~ ^[Yy]$ ]]; then
    sudo mv /usr/local/bin/ChromeOS_PowerControl/batterycontrol.conf /etc/init/
    echo "BatteryControl will start on boot."
    echo ""
else
    echo "BatteryControl must be started manually on boot."
fi

read -rp "Do you want to start BatteryControl now in the background? (y/n): " run_batterycontrol
echo ""
if [[ "$run_batterycontrol" =~ ^[Yy]$ ]]; then
    sudo /usr/local/bin/ChromeOS_PowerControl/batterycontrol start
    echo ""
else
    echo "Run with: sudo batterycontrol start"
    echo ""
fi


read -rp "Do you want PowerControl enabled on boot? Requires removing rootfs verification. (y/n): " move_powercontrolconf
echo ""
if [[ "$move_powercontrolconf" =~ ^[Yy]$ ]]; then
    sudo mv /usr/local/bin/ChromeOS_PowerControl/powercontrol.conf /etc/init/
    echo "PowerControl will start on boot."
    echo ""
else
    echo "PowerControl must be started manually on boot."
fi

read -rp "Do you want to start PowerControl now in the background?. (y/n): " run_powercontrol
echo ""
if [[ "$run_powercontrol" =~ ^[Yy]$ ]]; then
    sudo /usr/local/bin/ChromeOS_PowerControl/powercontrol start
    echo ""
else
    echo "You can run it later with: sudo powercontrol start"
    echo ""
fi

read -rp "Do you want FanControl enabled on boot? Requires removing rootfs verification. (y/n): " move_fancontrolconf
echo ""
if [[ "$move_fancontrolconf" =~ ^[Yy]$ ]]; then
    sudo mv /usr/local/bin/ChromeOS_PowerControl/fancontrol.conf /etc/init/
    echo "FanControl will start on boot."
    echo ""
else
    echo "FanControl must be started manually on boot."
fi

read -rp "Do you want to start FanControl now in the background?. (y/n): " run_fancontrol
echo ""
if [[ "$run_fancontrol" =~ ^[Yy]$ ]]; then
    sudo /usr/local/bin/ChromeOS_PowerControl/fancontrol start
    echo ""
else
    echo "You can run it later with: sudo fancontrol start"
    echo ""
fi

echo ""
echo "Commands with examples:"
echo ""
echo "sudo powercontrol                     # Show status"
echo "sudo powercontrol start               # Throttle CPU based on temperature curve"
echo "sudo powercontrol stop                # Default CPU temperature curve. no_turbo setting restored."
echo "sudo powercontrol no_turbo 1          # 0 is default (Intel Only) Turbo Boost On behavior."
echo "sudo powercontrol max_perf_pct 75     # 10 to 100%. 100 is default behavior; can be run standalone."
echo "sudo powercontrol min_perf_pct 50     # Minimum clockspeed CPU can reach at max_temp."
echo "sudo powercontrol max_temp 86         # Threshold when min_perf_pct is reached. Limit is 90 Celcius."
echo "sudo powercontrol min_temp 60         # Threshold when max_perf_pct is reached."
echo "sudo powercontrol monitor             # Updates log real-time in terminal window."
echo "sudo powercontrol help                # Shows a list of commands"
echo ""
echo "sudo batterycontrol start             # starts batterycontrol"
echo "sudo batterycontrol stop              # stops batterycontrol"
echo "sudo batterycontrol status            # shows status. Leave as a blank command for same effect."
echo "sudo batterycontrol set 80 75         # 80 is when charging stops; 75 is when charging may begin."
echo "sudo batterycontrol help              # Shows a list of commands"
echo ""
echo "sudo fancontrol                        # Show status"
echo "sudo fancontrol start                  # starts fancontrol"
echo "sudo fancontrol stop                   # stops fancontrol and restores default fan behavior."
echo "sudo fancontrol min_temp 50            # Threshold in C for min_fan speed is met."
echo "sudo fancontrol max_temp 90            # Threshold in C for max_fan speed is met."
echo "sudo fancontrol min_fan 0              # % in fan speed when temperature is at or below min_temp."
echo "sudo fancontrol max_fan 100            # % in fan speed when temperature is at or below max_temp."
echo "sudo fancontrol stepup 20              # % in fan granularity when temperature is climbing."
echo "sudo fancontrol stepdown 1             # % in fan granularity when temperature is falling."
echo "sudo fancontrol help                   # Shows a list of commands"
echo ""
echo "sudo powercontrol uninstall            # Global uninstaller"
echo "Alternative uninstall method:"
echo "sudo bash /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh"
echo ""
