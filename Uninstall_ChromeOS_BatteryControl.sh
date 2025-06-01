#!/bin/bash

echo "Uninstalling ChromeOS Battery Control!"
sudo initctl stop no_turbo 2>/dev/null
sudo initctl stop batterycontrol 2>/dev/null

echo
echo "Choose an option:"
echo "0: Quit"
echo "1: Remove no_turbo.conf from /etc/init"
echo "2: Remove batterycontrol.conf from /etc/init"
echo "3: Full Uninstall (remove all files, symlinks, and user config)"

read -rp "Enter (0-3): " choice

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
        ;;
    2)
        remove_file_with_message /etc/init/batterycontrol.conf
        ;;
    3)
        # Stop services
        sudo initctl stop no_turbo 2>/dev/null
        sudo initctl stop batterycontrol 2>/dev/null

        echo "Stopping background services..."

        # System files
        echo "Removing system files..."
        remove_file_with_message /etc/init/no_turbo.conf
        remove_file_with_message /etc/init/batterycontrol.conf

        # Symlink
        echo "Removing symlink..."
        remove_file_with_message /usr/local/bin/batterycontrol

        # Script directory
        if [ -d /usr/local/bin/ChromeOS_BatteryControl ]; then
            sudo rm -rf /usr/local/bin/ChromeOS_BatteryControl && echo "Removed: /usr/local/bin/ChromeOS_BatteryControl"
        else
            echo "Not found: /usr/local/bin/ChromeOS_BatteryControl"
        fi

        # User config and state
        echo "Removing user config files..."
        remove_file_with_message "$HOME/.batterycontrol_config"
        remove_file_with_message "$HOME/.batterycontrol_enabled"

        echo "Full uninstall complete."
        ;;
    *)
        echo "Invalid choice. Uninstall canceled."
        ;;
esac
