#!/bin/bash
sudo mkdir -p /usr/local/bin/ChromeOS_BatteryControl
echo "Enabling sudo in crosh or run in VT-2 is required!"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol -o /usr/local/bin/ChromeOS_BatteryControl/batterycontrol
echo " /usr/local/bin/ChromeOS_BatteryControl/batterycontrol downloaded."
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/Uninstall_ChromeOS_BatteryControl.sh -o /usr/local/bin/ChromeOS_BatteryControl/Uninstall_ChromeOS_BatteryControl.sh
echo " /usr/local/bin/ChromeOS_BatteryControl/Uninstall_ChromeOS_BatteryControl.sh downloaded."
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/LICENSE -o /usr/local/bin/ChromeOS_BatteryControl/LICENSE
echo " /usr/local/bin/ChromeOS_BatteryControl/LICENSE downloaded."
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/README.md -o /usr/local/bin/ChromeOS_BatteryControl/README.md
echo " /usr/local/bin/ChromeOS_BatteryControl/README.md downloaded."
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.conf -o /usr/local/bin/ChromeOS_BatteryControl/batterycontrol.conf
echo " /usr/local/bin/ChromeOS_BatteryControl/batterycontrol.conf downloaded."
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/no_turbo.conf -o /usr/local/bin/ChromeOS_BatteryControl/no_turbo.conf
echo " /usr/local/bin/ChromeOS_BatteryControl/no_turbo.conf downloaded."

sudo chmod +x /usr/local/bin/ChromeOS_BatteryControl/batterycontrol
sudo chmod +x /usr/local/bin/Uninstall_ChromeOS_BatteryControl.sh

read -rp "Do you want ChromeOS_BatteryControl to start on boot? to /etc/init? (y/n): " move_batterycontrol
if [[ "$move_batterycontrol" =~ ^[Yy]$ ]]; then
    sudo mv /usr/local/bin/ChromeOS_BatteryControl/batterycontrol.conf /etc/init/
    echo "Configuration files moved to /etc/init."
else
    echo "BatteryControl will not start with ChromeOS."
fi

read -rp "Do you Intel Turbo Boost disabled on boot? (y/n): " move_no_turbo
if [[ "$move_no_turbo" =~ ^[Yy]$ ]]; then
    sudo mv /usr/local/bin/ChromeOS_BatteryControl/no_turbo.conf /etc/init/
    echo "Turbo Boost will be disabled when restarting."
else
    echo "Turbo Boost will be enabled on restart."
fi

# Ask to create a symlink to run 'batterycontrol' globally
read -rp "Do you want to create a global command 'batterycontrol' for faster changes? (y/n): " link_cmd
if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
    sudo ln -sf /usr/local/bin/ChromeOS_BatteryControl/batterycontrol /usr/local/bin/batterycontrol
    echo "'batterycontrol' command is now available system-wide."
else
    echo "Skipped creating global command."
fi

# Ask to run batterycontrol now
read -rp "Do you want to run batterycontrol now? (y/n): " run_batterycontrol
if [[ "$run_batterycontrol" =~ ^[Yy]$ ]]; then
    sudo /usr/local/bin/ChromeOS_BatteryControl/batterycontrol
else
    echo "You can run it later with: sudo /usr/local/bin/ChromeOS_BatteryControl/batterycontrol"
fi

read -rp "Do you want to disable Intel Turbo Boost now? (y/n): " run_no_turbo
if [[ "$run_no_turbo" =~ ^[Yy]$ ]]; then
    echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
else
    echo "Turbo Boost will remain enabled."
fi

