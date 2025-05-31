# `#ffffff`ChromeOS Battery Control**

## Limit your Chromebook's battery charging limit to your liking instead of relying on Adaptive Charging or Enterprise Group Policies.

### How to Install - Paste the below command in a Crosh Shell:

`bash <(curl -s https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Downloader.sh)`

### This will download ChromeOS_BatteryControl to ~/tmp/ but it cannot run without VT-2!
### Open up the VT-2 console:

 `sudo mv ~/tmp/ChromeOS_BatteryControl /usr/local/bin/`

 ### Runing ChromeOS_BatteryControl will stay active until the machine restarts:
 `sudo bash batterycontrol.sh &`

 ### To kill ChromeOS_BatteryControl without restarting run:
 `ps aux | grep batterycontrol.sh` and then `sudo kill (process id)`
`
By default this script will prevent ChromeOS from charging the device beyond ~80%.
