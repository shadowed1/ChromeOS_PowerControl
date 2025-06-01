#!/bin/bash
echo "Downloading to: /home/chronos/user/tmp/ChromeOS_BatteryControl_Installer.sh"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Installer.sh -o /home/chronos/user/tmp/ChromeOS_BatteryControl_Installer.sh
echo "Download complete. You can run the installer with VT-2 after moving it to an executable location:"
echo "sudo mv /home/chronos/user/tmp/ChromeOS_BatteryControl_Installer.sh /usr/local/bin"
echo "sudo bash /usr/local/bin/ChromeOS_BatteryControl_Installer.sh"
