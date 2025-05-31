#!/bin/bash
curl -L https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/batterycontrol.sh -o ~/tmp/batterycontrol.sh
echo "Requires VT-2 console to finish install: sudo cp ~/tmp/batterycontrol.sh /usr/local/bin/ and sudo bash /usr/local/bin/batterycontrol.sh &"
