#!/bin/bash

echo "Uninstalling ChromeOS_BatteryControl..."

if [ -f "$HOME/.batterycontrol_pid" ]; then
    PID=$(cat "$HOME/.batterycontrol_pid")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "Stopping running BatteryControl process (PID $PID)..."
        kill "$PID"
    fi
    rm -f "$HOME/.batterycontrol_pid"
fi

rm -f "$HOME/.batterycontrol_enabled"

rm -f "$HOME/.batterycontrol_config"

if [ -L "/usr/local/bin/batterycontrol" ]; then
    echo "Removing global 'batterycontrol' command link..."
    sudo rm -f /usr/local/bin/batterycontrol
fi

if [ -f "/etc/init/batterycontrol.conf" ]; then
    echo "Removing batterycontrol.conf from /etc/init..."
    sudo rm -f /etc/init/batterycontrol.conf
fi

if [ -f "/etc/init/no_turbo.conf" ]; then
    echo "Removing no_turbo.conf from /etc/init..."
    sudo rm -f /etc/init/no_turbo.conf
fi

if [ -f "/usr/local/bin/ChromeOS_BatteryControl_Installer.sh" ]; then
    echo "Removing installer script..."
    sudo rm -f /usr/local/bin/ChromeOS_BatteryControl_Installer.sh
fi

if [ -d "/usr/local/bin/ChromeOS_BatteryControl" ]; then
    echo "Removing ChromeOS_BatteryControl directory..."
    sudo rm -rf /usr/local/bin/ChromeOS_BatteryControl
fi

echo "ChromeOS_BatteryControl has been fully uninstalled."
