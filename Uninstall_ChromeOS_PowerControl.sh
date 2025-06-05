#!/bin/bash

if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"
fi

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

echo "0: Quit"
echo "1: Remove only powercontrol.conf, batterycontrol.conf, fancontrol.conf, and no_turbo.conf from /etc/init (disables turbo on boot)."
echo "2: Full Uninstall (remove all files, symlinks, startup files, and user config for powercontrol, batterycontrol, and fancontrol)."

read -rp "Enter (0-2): " choice

case "$choice" in
    0)
        echo "Uninstall canceled."
        ;;
    1)
        echo "Removing init files..."
        remove_file_with_message /etc/init/no_turbo.conf
        remove_file_with_message /etc/init/batterycontrol.conf
        remove_file_with_message /etc/init/powercontrol.conf
        remove_file_with_message /etc/init/fancontrol.conf
        ;;
    2)
        echo "Stopping background services..."

        if systemctl list-units --type=service | grep -q "powercontrol"; then
            sudo systemctl stop powercontrol
            echo "Stopped powercontrol service."
        elif initctl list | grep -q "powercontrol"; then
            sudo initctl stop powercontrol
            echo "Stopped powercontrol service (upstart)."
        fi

        sudo $INSTALL_DIR/powercontrol max_perf_pct 100
        sudo $INSTALL_DIR/powercontrol stop
        sudo $INSTALL_DIR/powercontrol no_turbo 0
        sudo $INSTALL_DIR/batterycontrol stop
        sudo $INSTALL_DIR/fancontrol stop

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
        echo "Symlinks directory not found, skipping."

        echo "Removing logs..."
        remove_file_with_message /var/log/powercontrol.log
        remove_file_with_message /var/log/fancontrol.log
        remove_file_with_message /var/log/batterycontrol.log

        # Remove the installation directory if it's empty
        if [ -d "$INSTALL_DIR" ] && [ -z "$(ls -A "$INSTALL_DIR")" ]; then
            sudo rm -rf "$INSTALL_DIR" && echo "Removed: $INSTALL_DIR"
        else
            echo "Installation directory not found or still contains files: $INSTALL_DIR"
        fi

        echo "Full uninstall complete."
        ;;
    *)
        echo "Invalid option."
        ;;
esac
