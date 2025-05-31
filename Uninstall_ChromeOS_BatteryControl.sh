#!/bin/bash

echo "Uninstalling ChromeOS Battery Control!"
sudo initctl stop no_turbo 2>/dev/null
sudo initctl stop batterycontrol 2>/dev/null

echo
echo "Choose an option:"
echo "0: Quit"
echo "1: Remove no_turbo.conf from /etc/init"
echo "2: Remove batterycontrol.conf from /etc/init"
echo "3: Full Uninstall (remove all files and symlinks)"

read -rp "Enter (0-3): " choice

case "$choice" in
    0)
        echo "Uninstall canceled."
        ;;
    1)
        if [ -f /etc/init/no_turbo.conf ]; then
            sudo rm /etc/init/no_turbo.conf && echo "Removed: /etc/init/no_turbo.conf"
        else
            echo "Not found: /etc/init/no_turbo.conf"
        fi
        ;;
    2)
        if [ -f /etc/init/batterycontrol.conf ]; then
            sudo rm /etc/init/batterycontrol.conf && echo "Removed: /etc/init/batterycontrol.conf"
        else
            echo "Not found: /etc/init/batterycontrol.conf"
        fi
        ;;
    3)
        # Stop services
        sudo initctl stop no_turbo 2>/dev/null
        sudo initctl stop batterycontrol 2>/dev/null

        # Remove init configs
        sudo rm -f /etc/init/no_turbo.conf
        sudo rm -f /etc/init/batterycontrol.conf

        # Remove symlink if exists
        if [ -L /usr/local/bin/batterycontrol ]; then
            sudo rm /usr/local/bin/batterycontrol && echo "Removed symlink: /usr/local/bin/batterycontrol"
        fi

        # Remove script directory
        if [ -d /usr/local/bin/ChromeOS_BatteryControl ]; then
            sudo rm -rf /usr/local/bin/ChromeOS_BatteryControl && echo "Removed: /usr/local/bin/ChromeOS_BatteryControl"
        fi

        echo "Full uninstall complete."
        ;;
    *)
        echo "Invalid choice. Uninstall canceled."
        ;;
esac
