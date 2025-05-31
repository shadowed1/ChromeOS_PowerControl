# **ChromeOS Battery Control - created for ChromeOS 136+**
## Requires Developer Mode. 

### Clamp battery charging limit to preference instead of relying on Adaptive Charging and Policies.
### Optional features include starting BatteryControl and toggling off Intel Turbo Boost on boot automatically. 

__How to Install:__

- Go to Releases and download ChromeOS_BatteryControl_Installer wherever you want.

- Run it in VT-2 or with sudo enabled in crosh:

`sudo bash ChromeOS_BatteryControl_Installer.sh`

- Choose the options you want.

- Run the uninstaller.sh file in /sys/local/bin/ChromeOS_BatteryControl to uninstall.

- __Credits:__

Thanks to WesBosch (Wisteria for helping me learn to make an installer:
https://github.com/WesBosch

Thanks to DennyL for showing me how to enable sudo on crosh which gave me a lot of ideas. 


