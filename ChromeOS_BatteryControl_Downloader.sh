#!/bin/bash
echo "Downloading to: /home/chronos/ChromeOS_BatteryControl_Installer.sh"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Installer.sh -o /home/chronos/ChromeOS_BatteryControl_Installer.sh
chmod +x "/home/chronos/ChromeOS_BatteryControl_Installer.sh"
echo "Download complete. You can run the installer with VT-2: sudo /home/chronos/ChromeOS_BatteryControl_Installer.sh"
