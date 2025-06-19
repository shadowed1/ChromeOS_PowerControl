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
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/minioverride.c -o /home/chronos/user/MyFiles/
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/sudocrosh.sh -o /home/chronos/sc.sh
echo ""
echo "${BOLD}Copy paste the commands below:${RESET}"
echo ""
echo "Back in ${YELLOW}Crostini${RESET}, copy paste:"
echo "${CYAN}gcc ~/minioverride.c -o ~/minioverride.so -shared${CYAN}"
echo ""
echo "In the **Chrome Files** app, copy ${CYAN}minioverride.so${RESET} from My Files/Linux Files into My Files/"
echo ""
echo ""In ${RED}VT-2 as root${RESET} run:
echo "${BOLD}"
echo "sudo mkdir -p /usr/local/bin"
echo ""
echo "mv /home/chronos/user/MyFiles/minioverride.so /usr/local/bin/"
echo ""
echo "mv /home/chronos/user/MyFiles/sc.sh /usr/local/bin"
echo ""
echo "chmod +x /usr/local/bin/minioverride.so"

echo ""
echo "bash /usr/local/bin/sc.sh"
echo ""
echo "reboot${RESET}"
echo ""
