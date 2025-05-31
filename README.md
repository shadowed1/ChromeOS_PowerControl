# **ChromeOS Battery Control**

## Limit your Chromebook's battery charging limit to your liking instead of relying on Adaptive Charging or Enterprise Group Policies.

### How to Install - paste the below command in a Crosh Shell:

`bash <(curl -s https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Downloader.sh)`

### This will download ChromeOS_BatteryControl to /home/chronos/ but it cannot run without VT-2!
### Open up the VT-2 console:

 `sudo mv /home/chronos/ChromeOS_BatteryControl/ /usr/local/bin/`

### Set it as executable:
`sudo chmod +x /usr/local/bin/ChromeOS_BatteryControl/batterycontrol.sh`

 ### Running ChromeOS_BatteryControl will stay active until the machine restarts:
 `sudo bash /usr/local/bin//ChromeOS_BatteryControl/batterycontrol.sh &`

 ### To kill ChromeOS_BatteryControl without restarting run:
 `ps aux | grep batterycontrol.sh` and then `sudo kill (process id)`
`
By default this script will prevent ChromeOS from charging the device beyond ~80%.

### Credits:

Thanks to WesBosch (Wisteria for helping me learn!
https://github.com/WesBosch
