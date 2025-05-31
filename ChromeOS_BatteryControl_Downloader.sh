#!/bin/bash
echo "Downloadin to: /mnt/stateful_partition/ChromeOS_BatteryControl_Installer.sh"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Installer.sh -o /mnt/stateful_partition/ChromeOS_BatteryControl_Installer.sh
echo "Download complete. You can run the installer with VT-2:"
echo "sudo bash /mnt/stateful_partition/ChromeOS_BatteryControl_Installer.sh"
