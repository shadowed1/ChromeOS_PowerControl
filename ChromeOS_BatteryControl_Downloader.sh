#!/bin/bash
mkdir -p ~/tmp/ChromeOS_BatteryControl
echo "Downloading ChromeOS_BatteryControl!"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.sh -o ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/installer.sh -o ~/tmp/ChromeOS_BatteryControl/installer.sh
chmod +x ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
echo "ChromeOS_BatteryControl now requires running installer.sh downloaded in /home/chronos/user/tmp/ChromeOS_BatteryControl as root user in VT-2 console to finish installing!"
fi
