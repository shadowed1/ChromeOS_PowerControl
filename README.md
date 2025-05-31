# **ChromeOS Battery Control**

## Limit your Chromebook's battery charging limit to your liking instead of relying on Adaptive Charging or Enterprise Group Policies.

### How to Install - Paste the below command in a Crosh Shell:

`bash <(curl -s https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Downloader.sh)`

### This will download ChromeOS_BatteryControl but it cannot run without VT-2!
### Open up the VT-2 console command and run:


`sudo bash ~/tmp/ChromeOS_BatteryControl/installer.sh`

### After installing, cd to /usr/local/bin/ and run:
 `sudo mv ~/tmp/ChromeOS_BatteryControl /usr/local/bin/`
 `sudo bash batterycontrol.sh &`

By default this script will prevent ChromeOS from charging the device beyond ~80%. 
