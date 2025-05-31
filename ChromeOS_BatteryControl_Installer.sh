#!/bin/bash
mkdir -p /home/chronos/ChromeOS_BatteryControl
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.sh -o /home/chronos/ChromeOS_BatteryControl/batterycontrol.sh
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol_startup.sh -o /home/chronos/ChromeOS_BatteryControl/batterycontrol_startup.sh
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/no_turbo_startup.sh -o /home/chronos/ChromeOS_BatteryControl/no_turbo_startup.sh
echo "Requires VT-2 console to finish install: sudo mv ~/home/chronos/ChromeOS_BatteryControl/ /usr/local/bin/ and sudo bash /usr/local/bin/ChromeOS_BatteryControl/batterycontrol.sh &"
