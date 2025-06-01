# **ChromeOS Battery Control**
## Requires Developer Mode. 

### - Customize battery charging limit instead of relying on Adaptive Charging to maximize battery longevity. 
### - Features global commands and can optionally disable Intel Turbo Boost on boot automatically.

### __How to Install:__

- Open crosh shell and run:

`bash <(curl -s https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Downloader.sh)`

- The installer will be placed: `~/tmp/ChromeOS_BatteryControl/ChromeOS_BatteryControl_Installer.sh`

- In *VT-2* run:
- 
  `sudo mv ~/tmp/ChromeOS_BatteryControl/ChromeOS_BatteryControl_Installer.sh /usr/local/bin`
- `sudo bash /usr/local/bin/ChromeOS_BatteryControl_Installer.sh`
  
- The installer will have options to choose from.

__Commands:__
- `Examples:`
- `sudo batterycontrol start               # starts batterycontrolmonitoring`
- `sudo batterycontrol stop                # stops batterycontrolmonitoring`
- `sudo batterycontrol status              # shows status`
- `sudo batterycontrol set 80 75           # 80 is when charging stops; 75 is when charging may begin`
- `sudo batterycontrol no_turbo 1          # 0 is default Intel Turbo Boost On behavior.`
- `sudo batterycontrol max_perf_cap 75     # 10 - 100% of CPU clock speed range. More granular than no_turbo`
- `sudo batterycontrol help`
- `sudo batterycontrol uninstall`
- Alternative uninstall method: `sudo /usr/local/bin/ChromeOS_BatteryControl/Uninstall_ChromeOS_BatteryControl.sh`

__How It Works:__

- Uses ectool's chargecontrol to toggle between normal or idle.
- Check's CROS_USBPD_CHARGER0/online to see if it is plugged in or not
- Check's BAT0/capacity to measure when to control chargecontrol.
- Due to an ectool limitation, batterycontrol will require keeping the terminal active.
- ChromeOS reports slightly higher values than what ChromeOS_BatteryControl sets the charge limit to. 

__Bonus:__

- Enable sudo for crosh:
  
`https://gist.github.com/velzie/a5088c9ade6ec4d35435b9826b45d7a3`

 __Credits:__

Thanks to WesBosch (Wisteria for helping me learn to make an installer:
https://github.com/WesBosch

Thanks to DennyL for showing me how to enable sudo on crosh which gave me a lot of ideas. 


