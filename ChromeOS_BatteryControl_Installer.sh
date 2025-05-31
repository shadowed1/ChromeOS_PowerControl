#!/bin/bash
sudo mkdir -p ~/tmp/ChromeOS_BatteryControl
sudo chown -R $USER ~/tmp/ChromeOS_BatteryControl
echo "Downloading ChromeOS_BatteryControl!"
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.sh -o ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
sudo chmod +x ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
sudo install -Dt /usr/local/bin -m 755 ~/tmp/ChromeOS_BatteryControl/batterycontrol.sh
read -p "Do you want to run ChromeOS_BatteryControl  now? (y/n): " choice
if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo "Running ChromeOS_BatteryControl!"
    sudo bash /usr/local/bin/batterycontrol.sh &
else
    echo "ChromeOS_BatteryControl is ready to run at /usr/local/bin"
fi
