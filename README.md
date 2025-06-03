# **ChromeOS PowerControl**
## Requires Developer Mode. 

### - Customize battery charging limit instead of relying on Adaptive Charging to maximize battery longevity. 
### - Features global commands for ease of use. 
### Can optionally disable Intel Turbo Boost on boot automatically if user has rootfs verification disabled
### - Customize CPU clock speed in relation to temperature; unlike Intel's spicier approach.

### __How to Install:__

- Open crosh shell and run:

`bash <(curl -s https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/ChromeOS_PowerControl_Downloader.sh)`

- The installer will be placed: `~/tmp/ChromeOS_PowerControl/ChromeOS_PowerControl_Installer.sh`

- In *VT-2* run:
- 
  `sudo mv ~/tmp/ChromeOS_PowerControl_Installer.sh /usr/local/bin`
- `sudo bash /usr/local/bin/ChromeOS_PowerControl_Installer.sh`
  
- BatteryControl is able to run in the background but PowerControl is not. Both can be utilized by one terminal simultaneously!

__Commands:__
- `sudo powercontrol start               # Throttle CPU based on temperature curve`
- `sudo powercontrol stop                # Default CPU temperature curve. no_turbo setting restored.`
- `sudo powercontrol no_turbo 1          # 0 is default Intel Turbo Boost On behavior.`
- `sudo powercontrol max_perf_pct 75     # 10 to 100%. 100 is default behavior; can be run standalone.`
- `sudo powercontrol min_perf_pct 50     # Minimum clockspeed CPU can reach at max_temp.`
- `sudo powercontrol max_temp 86         # Threshold when min_perf_pct is reached. Limit is 90 Celcius.`
- `sudo powercontrol min_temp 60         # Threshold when max_perf_pct is reached.`
----------------------------------------------------------------------------------------------
  
- `sudo batterycontrol start               # starts batterycontrol`
- `sudo batterycontrol stop                # stops batterycontrol`
- `sudo batterycontrol status              # shows status`
- `sudo batterycontrol set 80 75           # 80 is when charging stops; 75 is when charging may begin`
- `sudo batterycontrol help`

- `sudo powercontrol uninstall            # Global uninstaller that will clean up after itself`
- Alternative uninstall method: `sudo /usr/local/bin/ChromeOS_PowerControl/Uninstall_ChromeOS_PowerControl.sh`

__How It Works:__

__PowerControl:__
- Uses Intel's native no_turbo and max_perf_pct for easy user control.
- Pairs max_perf_pct and x86_pkg_tmp to create a script for a user adjustable clockspeed-temperature curve.
- When running `sudo powercontrol start` temperature and cpu clock speed are measured.
- If $min_temp threshold is below a certain point, the CPU will be able to hit 100% of its speed.
- The closer the CPU approaches $max_temp, the lower its clockspeed will be.


__BatteryControl:__
- Uses ectool's chargecontrol to toggle between normal or idle.
- Check's CROS_USBPD_CHARGER0/online to see if it is plugged in or not
- Check's BAT0/capacity to measure when to control chargecontrol.
- ChromeOS reports slightly higher values than what batterycontrol sets the charge limit to. 

__Bonus:__

- Enable sudo for crosh:
  
`https://gist.github.com/velzie/a5088c9ade6ec4d35435b9826b45d7a3`

 __Credits:__

- Thanks to WesBosch for helping me learn to make an installer:
  https://github.com/WesBosch
- Thanks to DennyL on ChromeOS discord for showing me how to enable sudo on crosh, test out PowerControl, and provide many great suggestions. 


