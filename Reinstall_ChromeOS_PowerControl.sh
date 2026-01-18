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
CONFIG_FILE="/home/chronos/user/MyFiles/Downloads/ChromeOS_PowerControl_Config/config"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/ChromeOS_PowerControl_Installer.sh -o /home/chronos/user/ChromeOS_PowerControl_Installer.sh
sudo mkdir -p /usr/local/bin
sudo bash /home/chronos/user/ChromeOS_PowerControl_Installer.sh
