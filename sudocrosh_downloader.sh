#!/bin/bash
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)
echo "${CYAN}${BOLD}Downloading to: /home/chronos/sudocrosh.sh $RESET"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/sudocrosh.sh -o /home/chronos/sc.sh
echo "${GREEN}${BOLD}Download complete. Open VT-2, login as root, and run the following commands to enable sudo in crosh shell:${RESET}"
echo "${BOLD}sudo mkdir -p /usr/local/bin"
echo ""
echo "sudo mv /home/chronos/sudocrosh.sh /usr/local/bin"
echo ""
echo "sudo bash /usr/local/bin/ChromeOS_PowerControl_Installer.sh"
echo ""
echo "reboot${RESET}"
