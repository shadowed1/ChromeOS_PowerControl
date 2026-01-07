#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

INSTALL_DIR="@INSTALL_DIR@"
CONFIG_FILE="$INSTALL_DIR/config.sh"

sudo mkdir -p /usr/local/bin
sudo curl -fsSL "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/ChromeOS_PowerControl_Installer.sh" -o "/usr/local/bin/ChromeOS_PowerControl_Installer.sh"
echo "sudo mkdir -p /usr/local/bin"
echo "sudo chmod +x /usr/local/ChromeOS_PowerControl_Installer.sh"
echo "sudo -E /usr/local/bin/ChromeOS_PowerControl_Installer.sh"
sudo chmod +x /usr/local/bin/ChromeOS_PowerControl_Installer.sh
sudo -E /usr/local/bin/ChromeOS_PowerControl_Installer.sh
