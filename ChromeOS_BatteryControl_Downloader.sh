#!/bin/bash
mkdir /home/chronos/ChromeOS_BatteryControl/
echo "Downloading to: /home/chronos/ChromeOS_BatteryControl/"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Installer.sh -o /home/chronos/ChromeOS_BatteryControl/ChromeOS_BatteryControl_Installer.sh
echo "Download complete. You can run the installer with VT-2: sudo bash /home/chronos/ChromeOS_BatteryControl/ChromeOS_BatteryControl_Installer.sh"
