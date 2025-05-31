#!/bin/bash
echo "Uninstalling ChromeOS Battery Control!"
sudo initctl stop no_turbo 2>/dev/null
sudo initctl stop batterycontrol 2>/dev/null
if [ -f /etc/init/no_turbo.conf ]; then
    sudo rm /etc/init/no_turbo.conf
    echo "Removed: /etc/init/no_turbo.conf"
else
    echo "Not found: /etc/init/no_turbo.conf"
fi
if [ -f /etc/init/batterycontrol.conf ]; thenelif [ "$1" == "uninstall" ]; then
    echo "Choose an  option:"
    echo "0: Quit"
    echo "1: Remove no_turbo.conf in /etc/init (Turbo Boost will start enabled)"
    echo "2: Remove batterycontrol.conf in /etc/init (BatteryControl will not start automatically)"
    echo "3: Full Uninstall."

    read -rp "Enter (0-3): " choice

    case "$choice" in
        0)
            echo "Uninstall Cancelled."
            ;;
        1)
            if [ -f /etc/init/no_turbo.conf ]; then
                sudo rm /etc/init/no_turbo.conf && echo "Removed no_turbo.conf"
            else
                echo "/etc/init/no_turbo.conf not found."
            fi
            ;;
        2)
            if [ -f /etc/init/batterycontrol.conf ]; then
                sudo rm /etc/init/batterycontrol.conf && echo "Removed batterycontrol.conf"
            else
                echo "/etc/init/batterycontrol.conf not found."
            fi
            ;;
        3)
            if [ -x "/usr/local/bin/ChromeOS_BatteryControl/Uninstall_ChromeOS_BatteryControl.sh" ]; then
                /usr/local/bin/ChromeOS_BatteryControl/Uninstall_ChromeOS_BatteryControl.sh
            else
                echo "Uninstall_ChromeOS_BatteryControl.sh not found or is not executable."
                exit 1
            fi
            ;;
        *)
            echo "Invalid choice. Uninstall canceled."
            ;;
    esac
    exit 0

    sudo rm /etc/init/batterycontrol.conf
    echo "Removed: /etc/init/batterycontrol.conf"
else
    echo "Not found: /etc/init/batterycontrol.conf"
fi
if [ -d /usr/local/bin/ChromeOS_BatteryControl ]; then
    sudo rm -rf /usr/local/bin/ChromeOS_BatteryControl
    echo "Removed: /usr/local/bin/ChromeOS_BatteryControl"
else
    echo "Not found: /usr/local/bin/ChromeOS_BatteryControl"
fi
echo "Uninstall complete."
