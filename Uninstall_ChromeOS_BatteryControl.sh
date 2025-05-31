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
if [ -f /etc/init/batterycontrol.conf ]; then
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
