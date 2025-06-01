echo "0: Quit"
echo "1: Remove no_turbo.conf from /etc/init"
echo "2: Full Uninstall (remove all files, symlinks, and user config)"

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
        sudo initctl stop no_turbo 2>/dev/null
        echo "Stopping background services..."
        echo "Removing system files..."
        remove_file_with_message /etc/init/no_turbo.conf
        echo "Removing startup files..."
        remove_file_with_message /usr/local/bin/ChromeOS_PowerControl_Installer.sh
        echo "Removing symlink..."
        remove_file_with_message /usr/local/bin/powercontrol

        if [ -d /usr/local/bin/ChromeOS_PowerControl ]; then
            sudo rm -rf /usr/local/bin/ChromeOS_PowerControl && echo "Removed: /usr/local/bin/ChromeOS_PowerControl"
        else
            echo "Not found: /usr/local/bin/ChromeOS_PowerControl"
        fi

        echo "Removing user config files..."
        remove_file_with_message "$HOME/.powercontrol_config"
        remove_file_with_message "$HOME/.powercontrol_enabled"

        echo "Full uninstall complete."
        ;;
    *)
        echo "Invalid option."
        ;;
esac
