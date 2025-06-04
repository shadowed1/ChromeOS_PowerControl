#!/bin/bash

INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"

echo "0: Quit"
echo "1: Remove only powercontrol.conf, batterycontrol.conf, fancontrol.conf, and no_turbo.conf from /etc/init (disables turbo on boot)."
echo "2: Full Uninstall (remove all files, symlinks, startup files, and user config for powercontrol, batterycontrol, and fancontrol)."

read -rp "Enter (0-2): " choice

remove_file_with_message() {
    local file="$1"
    if [ -f "$file" ]; then
        sudo rm "$file" && echo "Removed: $file"
    elif [ -L "$file" ]; then
        sudo rm "$file" && echo "Removed symlink: $file"
    else
        echo "Not found: $file"
    fi
}

case "$choice" in
    0)
        echo "Uninstall canceled."
        ;;
    1)
        remove_file_with_message /etc/init/no_turbo.conf
        remove_file_with_message /etc/init/batterycontrol.conf
        remove_file_with_message /etc/init/powercontrol.conf
        remove_file_with_message /etc/init/fancontrol.conf
        ;;
    2)
        echo "Stopping background services..."
        sudo initctl stop no_turbo 2>/dev/null

        echo "Restoring default settings without needing to reboot."
        sudo powercontrol max_perf_pct 100
        sudo powercontrol stop
        sudo powercontrol no_turbo 0
        sudo batterycontrol stop
        sudo fancontrol stop
        

        echo "Removing startup files..."
        remove_file_with_message /etc/init/no_turbo.conf
        remove_file_with_message /etc/init/batterycontrol.conf
        remove_file_with_message /etc/init/powercontrol.conf
        remove_file_with_message /etc/init/fancontrol.conf

        echo "Removing installer..."
        remove_file_with_message /usr/local/bin/ChromeOS_PowerControl_Installer.sh

        echo "Removing symlinks..."
        remove_file_with_message /usr/local/bin/powercontrol
        remove_file_with_message /usr/local/bin/batterycontrol
        remove_file_with_message /usr/local/bin/fancontrol

        if [ -d "$INSTALL_DIR" ]; then
            sudo rm -rf "$INSTALL_DIR" && echo "Removed: $INSTALL_DIR"
        else
            echo "Not found: $INSTALL_DIR"
        fi

        echo "Removing user config files..."
        echo "Full uninstall complete."
        ;;
    *)
        echo "Invalid option."
        ;;
esac
