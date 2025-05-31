#!/bin/bash
echo "Downloading! Requires sudo in crosh to be enabled!"
sudo mkdir -p /usr/local/bin/ChromeOS_BatteryControl
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.sh -o /usr/local/bin/ChromeOS_BatteryControl/batterycontrol.sh
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol_startup.sh -o /usr/local/bin/ChromeOS_BatteryControl/batterycontrol_startup.sh
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/no_turbo_startup.sh -o /usr/local/bin/ChromeOS_BatteryControl/no_turbo_startup.sh
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/Uninstall_ChromeOS_BatteryControl.sh -o /usr/local/bin/ChromeOS_BatteryControl/Uninstall_ChromeOS_BatteryControl.sh
