#!/bin/bash
mkdir -p ~/tmp/ChromeOS_BatteryControl
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.sh -o ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
echo "Requires VT-2 console to finish install: sudo mv ~/tmp/ChromeOS_BatteryControl /usr/local/bin/ and sudo bash /usr/local/bin/ChromeOS_BatteryControl/batterycontrol.sh &"
