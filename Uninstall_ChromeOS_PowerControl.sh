#!/bin/bash
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)
INSTALL_DIR="@INSTALL_DIR@"
trap 'echo "Uninstall interrupted."; exit 1' SIGINT SIGTERM


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

echo "${GREEN}0: Quit$RESET"
echo "${YELLOW}1: Remove only powercontrol.conf, batterycontrol.conf, fancontrol.conf, and no_turbo.conf from /etc/init (disables turbo on boot).$RESET"
echo "${RED}2: Full Uninstall (remove all files, symlinks, startup files, and user config for powercontrol, batterycontrol, and fancontrol).$RESET"

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
        remove_file_with_message /etc/init/gpucontrol.conf
        remove_file_with_message /etc/init/sleepcontrol.conf
        ;;
    2)
        echo "Stopping background services..."
        sudo ectool backlight 1 2>/dev/null
        sudo bash "$INSTALL_DIR/powercontrol" stop 2>/dev/null
        sudo bash "$INSTALL_DIR/powercontrol" max_perf_pct 100 2>/dev/null
        sudo bash "$INSTALL_DIR/powercontrol" no_turbo 0 2>/dev/null
        sudo bash "$INSTALL_DIR/batterycontrol" stop 2>/dev/null
        sudo bash "$INSTALL_DIR/fancontrol" stop 2>/dev/null
        sudo bash "$INSTALL_DIR/gpucontrol" restore 2>/dev/null
        sudo bash "$INSTALL_DIR/sleepcontrol" mode freeze 2>/dev/null
        sudo bash "$INSTALL_DIR/sleepcontrol" stop 2>/dev/null
        sudo ectool chargecontrol normal 2>/dev/null
        remove_file_with_message "$INSTALL_DIR/no_turbo.conf"
        remove_file_with_message "$INSTALL_DIR/batterycontrol.conf"
        remove_file_with_message "$INSTALL_DIR/powercontrol.conf"
        remove_file_with_message "$INSTALL_DIR/fancontrol.conf"
        remove_file_with_message "$INSTALL_DIR/gpucontrol.conf"
        remove_file_with_message "$INSTALL_DIR/sleepcontrol.conf"
        remove_file_with_message "$INSTALL_DIR/version"
        remove_file_with_message /etc/init/no_turbo.conf
        remove_file_with_message /etc/init/batterycontrol.conf
        remove_file_with_message /etc/init/powercontrol.conf
        remove_file_with_message /etc/init/fancontrol.conf
        remove_file_with_message /etc/init/gpucontrol.conf
        remove_file_with_message /etc/init/sleepcontrol.conf

        remove_file_with_message /usr/local/bin/ChromeOS_PowerControl_Installer.sh

        remove_file_with_message /usr/local/bin/powercontrol
        remove_file_with_message /usr/local/bin/batterycontrol
        remove_file_with_message /usr/local/bin/fancontrol
        remove_file_with_message /usr/local/bin/gpucontrol
        remove_file_with_message /usr/local/bin/sleepcontrol

        remove_file_with_message /var/log/powercontrol.log
        remove_file_with_message /var/log/fancontrol.log
        remove_file_with_message /var/log/batterycontrol.log
        remove_file_with_message /var/log/gpucontrol.log
        remove_file_with_message /var/log/sleepcontrol.log
        remove_file_with_message "$INSTALL_DIR/config.sh" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.fancontrol_enabled" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.powercontrol_enabled" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.batterycontrol_enabled" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.sleepcontrol_enabled" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.last_simulated_times" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.last_fake_activity" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/Reinstall_ChromeOS_PowerControl.sh" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/config.sh.bak" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.fan_curve_pid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.fan_curve_running" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.install_path" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.fancontrol_pid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.powercontrol_pid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.batterycontrol_pid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.gpucontrol_enabled" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.gpucontrol_pid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.fancontrol_tail_fan_monitor.pid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.powercontrol_tail_fan_monitor.pid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.fancontrol_monitor.pid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.powercontrol_monitor.pid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.sleepcontrol_lock" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.sleepcontrol_monitor.pid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.sleepcontrol_pid.lock" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.mem_sleep_watcher.lock" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.sleepcontrol_pid.lid" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/last_fake_activity_ts" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/last_real_activity_ts" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.last_power_state" 2>/dev/null
        sudo rm -rf "$INSTALL_DIR/sleep" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/config" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/deep_suspend.sh" 2>/dev/null
        sudo rm -f "/usr/local/bin/.ChromeOS_PowerControl.install_dir" 2>/dev/null
        sudo rm -f "/usr/local/bin/fancontrol_conf.sh" 2>/dev/null
        sudo rm -f "/usr/local/bin/powercontrol_conf.sh" 2>/dev/null
        sudo rm -f "/usr/local/bin/sleepcontrol_conf.sh" 2>/dev/null
        sudo rm -f "/usr/local/bin/batterycontrol_conf.sh" 2>/dev/null
        sudo rm -f "/usr/local/bin/gpucontrol_conf.sh" 2>/dev/null
        sudo rm -f "$INSTALL_DIR/.saved_brightness" 2>/dev/null
        rm -rf /home/chronos/user/MyFiles/Downloads/ChromeOS_PowerControl_Config 2>/dev/null
        remove_file_with_message "$INSTALL_DIR/powercontrol"
        remove_file_with_message "$INSTALL_DIR/fancontrol"
        remove_file_with_message "$INSTALL_DIR/batterycontrol"
        remove_file_with_message "$INSTALL_DIR/gpucontrol"
        remove_file_with_message "$INSTALL_DIR/sleepcontrol"
        remove_file_with_message "$INSTALL_DIR/LICENSE"
        remove_file_with_message "$INSTALL_DIR/README.md"
        remove_file_with_message "$INSTALL_DIR/Uninstall_ChromeOS_PowerControl.sh"

        if [ -d "$INSTALL_DIR" ] && [ -z "$(ls -A "$INSTALL_DIR")" ]; then
            sudo rm -rf "$INSTALL_DIR" && echo "Removed: $INSTALL_DIR"
        else
            echo "Installation directory not found or still contains files: $INSTALL_DIR"
        fi
        echo "Stopping PowerControl processes..."
        echo ""
        sleep 1
echo "${RED}╔═══════════════════════════════╗${RESET}"
echo "${YELLOW}║ ╔═══════════════════════════╗ ║${RESET}"
echo "${GREEN}║ ║ ╔═══════════════════════╗ ║ ║${RESET}"
echo "${RESET}║ ║ ║  Uninstall Complete!  ║ ║ ║${RESET}"
echo "${CYAN}║ ║ ╚═══════════════════════╝ ║ ║${RESET}"
echo "${BLUE}║ ╚═══════════════════════════╝ ║${RESET}"
echo "${MAGENTA}╚═══════════════════════════════╝${RESET}"
echo ""
        sudo pkill -f "/usr/local/bin/gpucontrol" >/dev/null 2>&1
        sudo pkill -f "/usr/local/bin/fancontrol" >/dev/null 2>&1
        sudo pkill -f "/usr/local/bin/sleepcontrol" >/dev/null 2>&1
        sudo pkill -f "/usr/local/bin/batterycontrol" >/dev/null 2>&1
        sudo pkill -f "/usr/local/bin/powercontrol" >/dev/null 2>&1

trap '' SIGTERM

exit 0
        ;;
    *)
        echo "${RED}Invalid option.$RESET"
        exit 1
        ;;
esac
