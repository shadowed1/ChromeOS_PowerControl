# **ChromeOS PowerControl**
## Requires Developer Mode. 

### - Customize battery charging limit instead of relying on Adaptive Charging to maximize battery longevity. 
### - Features global commands and can optionally disable Intel Turbo Boost on boot automatically.
### - [In-progress] Customize CPU clock speed in relation to temperature; unlike Intel's spicier approach.

### __How to Install:__

- Open crosh shell and run:

`bash <(curl -s https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/ChromeOS_PowerControl_Downloader.sh)`

- The installer will be placed: `~/tmp/ChromeOS_PowerControl/ChromeOS_PowerControl_Installer.sh`

- In *VT-2* run:
- 
  `sudo mv ~/tmp/ChromeOS_PowerControl/ChromeOS_PowerControl_Installer.sh /usr/local/bin`
- `sudo bash /usr/local/bin/ChromeOS_PowerControl_Installer.sh`
  
- The installer will have options to choose from.

__Commands:__
- `Examples:`
- `sudo powercontrol start               # Throttle CPU based on temperature`
- `sudo powercontrol stop                # Default CPU temperature curve`  
- `sudo powercontrol no_turbo 1          # 0 is default Intel Turbo Boost On behavior.`
- `sudo powercontrol max_perf_pct 75     # 10 - 100% of CPU clock speed range. More granular.`
- `sudo powercontrol help`
- 
- `sudo batterycontrol start               # starts batterycontrol`
- `sudo batterycontrol stop                # stops batterycontrol`
- `sudo batterycontrol status              # shows status`
- `sudo batterycontrol set 80 75           # 80 is when charging stops; 75 is when charging may begin`
- `sudo batterycontrol help`
-
- `sudo powercontrol uninstall            # Global uninstaller`
- Alternative uninstall method: `sudo /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh`

__How It Works:__

__BatteryControl:__
- Uses ectool's chargecontrol to toggle between normal or idle.
- Check's CROS_USBPD_CHARGER0/online to see if it is plugged in or not
- Check's BAT0/capacity to measure when to control chargecontrol.
- ChromeOS reports slightly higher values than what batterycontrol sets the charge limit to. 

__PowerControl:__
- Uses Intel's native no_turbo and max_perf_pct easy user control.
- Pairs max_perf_pct and x86_pkg_tmp for a user adjustable clockspeed-temperature curve.

__Bonus:__

- Enable sudo for crosh:
  
`https://gist.github.com/velzie/a5088c9ade6ec4d35435b9826b45d7a3`

 __Credits:__

- Thanks to WesBosch for helping me learn to make an installer:
  https://github.com/WesBosch
- Thanks to DennyL for showing me how to enable sudo on crosh which gave me a lot of ideas. 


