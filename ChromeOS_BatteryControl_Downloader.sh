#!/bin/bash
echo "If blank it will go to /home/chronos/user/tmp/"
echo "Choose location for ChromeOS_BatteryControl_Installer.sh:"
read -rp "Enter full path (or press Enter for default [/usr/local/bin/ChromeOS_BatteryControl]): " custom_path

# Use default if input is empty
if [ -z "$custom_path" ]; then
    custom_path="/home/chronos/user/tmp/ChromeOS_BatteryControl"
fi

# Create the directory if it doesn't exist
mkdir -p "$custom_path"

# Download the installer to the chosen path
echo "Downloading to: $custom_path/batterycontrol"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Installer.sh \
    -o "$custom_path/batterycontrol"

# Make it executable
chmod +x "$custom_path/batterycontrol"

echo "Download complete. You can run it with VT-2: sudo $custom_path/batterycontrol"
