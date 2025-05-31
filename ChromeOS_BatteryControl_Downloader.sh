#!/bin/bash
mkdir -p ~/tmp/ChromeOS_BatteryControl
echo "Downloading ChromeOS_BatteryControl to ~/tmp/ChromeOS_BatteryControl!"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.sh -o ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/installer.sh -o ~/tmp/ChromeOS_BatteryControl/installer.sh
echo "ChromeOS_BatteryControl requires running installer.sh downloaded in ~/tmp/ChromeOS_BatteryControl as root user in VT-2 console to finish installing!"
echo "In the VT-2 console run: sudo bash ~/tmp/ChromeOS_BatteryControl/installer.sh"
chmod +x ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
chmod +x ~/tmp/ChromeOS_BatteryControl/installer.sh
