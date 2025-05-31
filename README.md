# **ChromeOS Battery Control - created for ChromeOS 136+**
## Requires Developer Mode. 

### Clamp battery charging limit to preference instead of relying on Adaptive Charging and Policies.
### Features global commands and have BatteryControl + disabling Intel Turbo Boost boot automatically.

__How to Install:__

- Go to Releases and download ChromeOS_BatteryControl_Installer wherever you want.
- Run it in VT-2 or with sudo enabled in crosh:

`sudo bash ChromeOS_BatteryControl_Installer.sh`

- Choose the options you want.

__Commands:__

- `batterycontrol toggle on           # off to disable`
- `batterycontrol set 80 75           # 80 is when charging stops; 75 is when charging may begin`
- `batterycontrol no_turbo 1          # 0 is default Intel Turbo Boost On behavior.`
- `batterycontrol uninstall`
- Alternative uninstall method: `sudo /usr/local/bin/ChromeOS_BatteryControl/Uninstall_ChromeOS_BatteryControl.sh`

 __Credits:__

Thanks to WesBosch (Wisteria for helping me learn to make an installer:
https://github.com/WesBosch

Thanks to DennyL for showing me how to enable sudo on crosh which gave me a lot of ideas. 


