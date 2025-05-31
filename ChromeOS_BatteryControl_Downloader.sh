#!/bin/bash
echo "Choose location for ChromeOS_BatteryControl_Installer.sh:"
read -rp "Enter full path (or press Enter for [/home/chronos/user/tmp/ChromeOS_BatteryControl]): " custom_path

if [ -z "$custom_path" ]; then
    custom_path="/home/chronos/user/tmp/ChromeOS_BatteryControl"
fi

mkdir -p "$custom_path"
echo "Downloading to: $custom_path/ChromeOS_BatteryControl_Installer.sh"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Installer.sh \
    -o "$custom_path/ChromeOS_BatteryControl_Installer.sh"

chmod +x "$custom_path/ChromeOS_BatteryControl_Installer.sh"
echo "Download complete. You can run the installer with VT-2: sudo $custom_path/ChromeOS_BatteryControl_Installer.sh"
