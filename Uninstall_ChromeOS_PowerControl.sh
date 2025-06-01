echo "0: Quit"
echo "1: Remove no_turbo.conf from /etc/init"
echo "2: Full Uninstall (remove all files, symlinks, and user config for powercontrol & batterycontrol)"

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
        ;;
    2)
        echo "Stopping background services..."
        sudo initctl stop no_turbo 2>/dev/null

        echo "Removing startup files..."
        remove_file_with_message /etc/init/no_turbo.conf

        echo "Removing installer..."
        remove_file_with_message /usr/local/bin/ChromeOS_PowerControl_Installer.sh

        echo "Removing symlinks..."
        remove_file_with_message /usr/local/bin/ChromeOS_PowerControl/powercontrol
        remove_file_with_message /usr/local/bin/ChromeOS_PowerControl/batterycontrol

        if [ -d /usr/local/bin/ChromeOS_PowerControl ]; then
            sudo rm -rf /usr/local/bin/ChromeOS_PowerControl && echo "Removed: /usr/local/bin/ChromeOS_PowerControl"
        else
            echo "Not found: /usr/local/bin/ChromeOS_PowerControl"
        fi

        echo "Removing user config files..."
        remove_file_with_message "$HOME/.powercontrol_config"
        remove_file_with_message "$HOME/.powercontrol_enabled"
        remove_file_with_message "$HOME/.batterycontrol_config"
        remove_file_with_message "$HOME/.batterycontrol_enabled"

        echo "Full uninstall complete."
        ;;
    *)
        echo "Invalid option."
        ;;
esac
