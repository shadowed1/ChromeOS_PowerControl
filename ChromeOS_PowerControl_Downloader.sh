#!/bin/bash
echo "Beta"
echo "Downloading to: /home/chronos/ChromeOS_PowerControl_Installer.sh"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/beta/ChromeOS_PowerControl_Installer.sh -o /home/chronos/ChromeOS_PowerControl_Installer.sh
echo "Download complete. You can run the installer with VT-2 after moving it to an executable location:"
echo ""
echo "sudo mv /home/chronos/ChromeOS_PowerControl_Installer.sh /usr/local/bin"
echo ""
echo "sudo bash /usr/local/bin/ChromeOS_PowerControl_Installer.sh"
echo ""
