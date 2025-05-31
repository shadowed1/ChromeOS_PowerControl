#!/bin/bash
mkdir -p /home/chronos/ChromeOS_BatteryControl
echo "Downloading ChromeOS_BatteryControl to /home/chronos/ChromeOS_BatteryControl!"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.sh -o /home/chronos/ChromeOS_BatteryControl/batterycontrol.sh
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/installer.sh -o /home/chronos/ChromeOS_BatteryControl/installer.sh
echo "ChromeOS_BatteryControl requires running installer.sh downloaded in ~/tmp/ChromeOS_BatteryControl as root user in VT-2 console to finish installing.
In the VT-2 console run: sudo bash /home/chronos/ChromeOS_BatteryControl/installer.sh"
chmod +x /home/chronos/ChromeOS_BatteryControl/batterycontrol.sh
chmod +x /home/chronos/ChromeOS_BatteryControl/installer.sh
