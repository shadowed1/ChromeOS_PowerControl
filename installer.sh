#!/bin/bash
if [ -f ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh ]; then
    sudo install -Dt /usr/local/bin -m 755 ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
    sudo chmod +x /usr/local/bin/batterycontrol.sh
    echo "ChromeOS_BatteryControl script installed to /usr/local/bin."
else
    echo "Error: batterycontrol.sh script does not exist in ~/tmp/ChromeOS_BatteryControl."
    exit 1
    
read -p "Would you like to run ChromeOS_BatteryControl now? (y/n): " run_choice

if [[ "$run_choice" == "y" || "$run_choice" == "Y" ]]; then
    echo "Running ChromeOS_BatteryControl..."
    sudo bash /usr/local/bin/batterycontrol.sh &
else
    echo "ChromeOS_BatteryControl is ready to run with sudo bash /usr/local/bin/batterycontrol.sh."
fi
