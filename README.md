# **ChromeOS Battery Control - created for ChromeOS 136+**
## Adjust the Chromebook's battery charging limit instead of relying on Adaptive Charging or Enterprise Group Policies.

__How to Install - paste the below command in a crosh shell:__

`bash <(curl -s https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Downloader.sh)`

- __This will download ChromeOS_BatteryControl to /home/chronos/ but it cannot run without VT-2:__

`sudo mv /home/chronos/ChromeOS_BatteryControl/ /usr/local/bin/`

- __Set it as executable in VT-2:__

`sudo chmod +x /usr/local/bin/ChromeOS_BatteryControl/batterycontrol.sh`

- __Running ChromeOS_BatteryControl will stay active until the machine restarts:__

`sudo bash /usr/local/bin//ChromeOS_BatteryControl/batterycontrol.sh &`

- __To kill ChromeOS_BatteryControl without restarting run:__

`ps aux | grep batterycontrol.sh` and then `sudo kill (process id)`
 
- __By default this script will prevent ChromeOS from charging the device beyond ~80%. 
- Use your favorite text editor to tweak the battery charge limit!__ 

- __Bonus: Disable Intel Turbo Boost in VT-2:__

`echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null`

- __Credits:__

Thanks to WesBosch (Wisteria for helping me learn!
https://github.com/WesBosch
