#!/bin/bash
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

prompt_confirm() {
    echo
    read -p "${YELLOW}Are you sure? [Y/n]: ${RESET}" confirm
    confirm=${confirm,,} # lowercase
    if [[ -z "$confirm" || "$confirm" == "y" || "$confirm" == "yes" ]]; then
        return 0
    else
        echo "${RED}Aborted by user.${RESET}"
        exit 1
    fi
}

reboot_prompt() {
    echo
    read -p "${GREEN}Changes applied. Reboot now? [Y/n]: ${RESET}" confirm
    confirm=${confirm,,}
    if [[ -z "$confirm" || "$confirm" == "y" || "$confirm" == "yes" ]]; then
        echo "${YELLOW}Rebooting...${RESET}"
        sleep 2
        reboot
    else
        echo "${YELLOW}You must reboot manually for changes to take effect.${RESET}"
    fi
}

clear
echo "${BOLD}${CYAN}Enable sudo in crosh!${RESET}"
echo "${BLUE}"
echo "1) disable rootfs verification (Dev Mode required)${RESET}"
echo "${MAGENTA}"
echo "2) Install minioverride.so (requires rootfs verification disabled)${RESET}"
echo "${RED}"
echo "q) Quit"
echo "${RESET}"

read -p "${GREEN}Select an option [1 / 2 / q]: ${RESET}" choice

case "$choice" in
    1)
        echo
        echo "${YELLOW}This will run disable rootfs verification by running:${RESET}"
        echo "/usr/libexec/debugd/helpers/dev_features_rootfs_verification"
        /usr/libexec/debugd/helpers/dev_features_rootfs_verification
        reboot_prompt
        ;;
    2)
        echo
        echo "${YELLOW}You must disable rootfs verification to proceed.${RESET}"
        prompt_confirm

        if [ ! -f "/home/chronos/user/MyFiles/minioverride.so" ]; then
            echo "${RED}File not found: /home/chronos/user/MyFiles/minioverride.so${RESET}"
            exit 1
        fi

        echo "${GREEN}Copying minioverride.so${RESET}"
        mkdir -p /usr/local/bin
        cp /home/chronos/user/MyFiles/minioverride.so /usr/local/bin/
        chmod +x /usr/local/bin/minioverride.so

        echo "${GREEN}Patching /etc/init/ui.conf...${RESET}"
        sed -i '1s/^/env LD_PRELOAD=\/usr\/local\/bin\/minioverride.so\n/' /etc/init/ui.conf 

        reboot_prompt
        ;;
    q|Q)
        echo "${YELLOW}Exiting installer.${RESET}"
        exit 0
        ;;
    *)
        echo "${RED}Invalid selection. Exiting.${RESET}"
        exit 1
        ;;
esac
