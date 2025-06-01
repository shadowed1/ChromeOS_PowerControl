    #!/bin/bash
    sudo mkdir -p /usr/local/bin/ChromeOS_PowerControl
    echo "Enabling sudo in crosh or run in VT-2 is required!"
    curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/powercontrol -o /usr/local/bin/ChromeOS_PowerControl/powercontrol
    echo " /usr/local/bin/ChromeOS_PowerControl/powercontrol downloaded."
    curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/batterycontrol -o /usr/local/bin/ChromeOS_PowerControl/batterycontrol
    echo " /usr/local/bin/ChromeOS_PowerControl/batterycontrol downloaded."
    curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/Uninstall_ChromeOS_PowerControl.sh -o /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh
    echo " /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh downloaded."
    curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/LICENSE -o /usr/local/bin/ChromeOS_PowerControl/LICENSE
    echo " /usr/local/bin/ChromeOS_PowerControl/LICENSE downloaded."
    curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/README.md -o /usr/local/bin/ChromeOS_PowerControl/README.md
    echo " /usr/local/bin/ChromeOS_PowerControl/README.md downloaded."
    curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/no_turbo.conf -o /usr/local/bin/ChromeOS_PowerControl/no_turbo.conf
    echo " /usr/local/bin/ChromeOS_PowerControl/no_turbo.conf downloaded."
    
    sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/powercontrol
    sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/batterycontrol
    sudo chmod +x /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh

    CONFIG_FILE="$HOME/.batterycontrol_config"
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "CHARGE_MAX=77" > "$CONFIG_FILE"
        echo "CHARGE_MIN=74" >> "$CONFIG_FILE"
        echo "Default config created at $CONFIG_FILE"
    else
        echo "Config file already exists at $CONFIG_FILE"
    fi

    CONFIG_FILE="$HOME/.powercontrol_config"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "MAX_TEMP_K=358" > "$CONFIG_FILE"    # 85°C in Kelvin
    echo "MAX_PERF_PCT=85" >> "$CONFIG_FILE" # Default max performance %
    echo "Default config created at $CONFIG_FILE"
else
    echo "Config file already exists at $CONFIG_FILE"
fi

    
    read -rp "Do you Intel Turbo Boost disabled on boot? (y/n): " move_no_turbo
    if [[ "$move_no_turbo" =~ ^[Yy]$ ]]; then
        sudo mv /usr/local/bin/ChromeOS_PowerControl/no_turbo.conf /etc/init/
        echo "Turbo Boost will be disabled when restarting."
    else
        echo "Turbo Boost will be enabled on restart."
    fi

    read -rp "Do you want to disable Intel Turbo Boost now? (y/n): " run_no_turbo
    if [[ "$run_no_turbo" =~ ^[Yy]$ ]]; then
        echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null
    else
        echo "Turbo Boost will remain enabled."
    fi
    
    read -rp "Do you want to create a global command 'powercontrol' for faster changes? (y/n): " link_cmd
    if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
        sudo ln -sf /usr/local/bin/ChromeOS_PowerControl/powercontrol /usr/local/bin/powercontrol
        echo "'powercontrol' command is now available system-wide."
    else
        echo "Skipped creating global command."
    fi

    read -rp "Do you want to create a global command 'batterycontrol' for faster changes? (y/n): " link_cmd
    if [[ "$link_cmd" =~ ^[Yy]$ ]]; then
        sudo ln -sf /usr/local/bin/ChromeOS_PowerControl/batterycontrol /usr/local/bin/batterycontrol
        echo "'batterycontrol' command is now available system-wide."
    else
        echo "Skipped creating global command."
    fi
    
