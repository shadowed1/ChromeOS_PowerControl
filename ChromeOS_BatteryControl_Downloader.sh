#!/bin/bash
mkdir -p ~/home/chronos/ChromeOS_BatteryControl
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.sh -o ~/home/chronos/ChromeOS_BatteryControl/batterycontrol.sh
echo "Requires VT-2 console to finish install: sudo mv ~/home/chronos/ChromeOS_BatteryControl/ /usr/local/bin/ and sudo bash /usr/local/bin/ChromeOS_BatteryControl/batterycontrol.sh &"
