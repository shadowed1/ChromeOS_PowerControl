#!/bin/bash
mkdir -p ~/tmp/ChromeOS_BatteryControl
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.sh -o ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/installer.sh -o ~/tmp/ChromeOS_BatteryControl/installer.sh
echo "Requires VT-2 console to finish install: sudo bash ~/tmp/ChromeOS_BatteryControl/installer.sh"
chmod +x ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
chmod +x ~/tmp/ChromeOS_BatteryControl/installer.sh
