


 ### *A suite of lightweight shell scripts providing hardware control for ChromeOS.*
 <br>
 <br>
 
<p align="center">
  <img src="https://i.imgur.com/uELNNt2.png" alt="logo" width="300" />
</p>
 
<br>

### How to Install:
Open Crosh (ctrl-alt-t), enter `shell`, copy paste, and run: 

 <pre>bash <(curl -s "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/ChromeOS_PowerControl_Downloader.sh?$(date +%s)")</pre>

<p align="center">
  <img src="https://i.imgur.com/fh8dBwa.png" alt="logo" />
</p>

<br> <br>

### Now with GUI support:

<br>

<p align="center">
  <img src="https://i.imgur.com/jubxhuM.png" alt="logo" width="600" />
</p>
<br>

### GUI app for Crostini (run in Linux):
```
sudo apt install gedit gnome-themes-extra gnome-icon-theme -y
sudo curl -fsSL "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/gui.py" -o /bin/powercontrol-gui 2>/dev/null
sudo chmod +x /bin/powercontrol-gui 2>/dev/null
alias powercontrol-gui='sudo -E powercontrol-gui'

sudo tee /usr/share/applications/powercontrol-gui.desktop > /dev/null <<'EOF'
[Desktop Entry]
Exec=/usr/bin/powercontrol-gui
StartupNotify=true
Terminal=false
Icon=ChromeOS_PowerControl
Type=Application
Categories=Utility
Version=1.0
EOF

sudo curl -Ls https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/ChromeOS_PowerControl.png -o /usr/share/icons/hicolor/256x256/apps/ChromeOS_PowerControl.png

```
Share Downloads folder with Linux and then run `powercontrol-gui` in Crostini. 
<br><br>
### GUI app for Chard (run inside ChromeOS shell):
```
if [[ -n "${CHARD_ROOT:-}" ]]; then
    sudo -E curl -fsSL "https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/gui.py" -o "$CHARD_ROOT/bin/powercontrol-gui" 2>/dev/null
    sudo chmod +x "$CHARD_ROOT/bin/powercontrol-gui" 2>/dev/null
fi
```
<br><br>
- Can use global commands for ease of use, has a unified config file, and the ability to change settings in real-time. 
- Contains a feature-rich installer, an uninstaller that cleans up after itself, and logs stored in /var/log/ for statistics.
- Optionally have BatteryControl, PowerControl, FanControl, GPUControl, and SleepControl start on boot if user has rootfs verification disabled.
- Requires Developer Mode - Supports AMD, ARM, and Intel.


<br> <br> 


- The installer will be placed: <br>

  `/home/chronos/ChromeOS_PowerControl/ChromeOS_PowerControl_Installer.sh`

- In *VT-2* or *crosh shell with sudo enabled* run:

 `sudo mkdir -p /usr/local/bin` <br>
 `sudo mv /home/chronos/ChromeOS_PowerControl_Installer.sh /usr/local/bin` <br>
 `sudo bash /usr/local/bin/ChromeOS_PowerControl_Installer.sh`
<br>

 - To disable rootfs verification and enable sudo in crosh check out sudoCrosh by pasting this in crosh shell:
<pre>bash <(curl -s "https://raw.githubusercontent.com/shadowed1/sudoCrosh/main/sudocrosh_downloader.sh?$(date +%s)")</pre>
<br>

- Installer has prompts to customize installation.
- PowerControl, BatteryControl, FanControl, and SleepControl can run in the background and can be adjusted in real-time.
<br><br><br><br>

__PowerControl commands with examples:__                                
                                                                                                     
  `powercontrol                    # Show status`                                                      
  `powercontrol all                # Show status of all ChromeOS_PowerControl components`              
  `powercontrol help               # Help menu`                                                        
  `sudo powercontrol start         # Throttle CPU based on temperature curve`                          
  `sudo powercontrol stop          # Restore default CPU settings`                                     
  `sudo powercontrol no_turbo 1    # 0 = Enable, 1 = Disable Turbo Boost`                              
  `sudo powercontrol max 75        # Set max performance percentage`                                   
  `sudo powercontrol min 50        # Set minimum performance at max temp`                              
  `sudo powercontrol max_temp 86   # Max temperature threshold - Limit is 90°C`                        
  `sudo powercontrol min_temp 60   # Min temperature threshold`                                        
  `sudo powercontrol hotzone 78    # Temperature threshold for aggressive thermal management`          
  `sudo powercontrol ramp_up 15    # % in steps CPU will increase in clockspeed per second`            
  `sudo powercontrol ramp_down 20  # % in steps CPU will decrease in clockspeed per second`            
  `sudo powercontrol hotzone 78    # Temperature threshold for aggressive thermal management`          
  `sudo powercontrol poll 1        # PowerControl polling rate in seconds (0.1s - 5s)`                 
  `sudo powercontrol monitor       # Toggle live temperature monitoring`                               
  `sudo powercontrol startup       # Copy or Remove no_turbo.conf & powercontrol.conf at: /etc/init/`  
  `sudo powercontrol reinstall     # Redownload and reinstall ChromeOS_PowerControl from Github`       
  `sudo powercontrol uninstall     # Uninstall ChromeOS_PowerControl`                                  
  `sudo powercontrol version       # Check PowerControl version`                                                                                           

<br><br>
                                                                           
  __BatteryControl commands with examples:__                       
                                                                                    
  `batterycontrol               # Check BatteryControl status`                     
  `batterycontrol help          # Help menu`                                          
  `sudo batterycontrol start    # Start BatteryControl`                               
  `sudo batterycontrol stop     # Stop BatteryControl`                                
  `sudo batterycontrol 77       # Charge limit set to 77% - Minimum allowed is 14%`
  `sudo batterycontrol usage    # See power consumption in real-time.`
  `sudo batterycontrol monitor  # Toggle on/off live monitoring in terminal.` 
  `sudo batterycontrol startup  # Copy or Remove batterycontrol.conf at: /etc/init/`

<br>
<br>
                                                                                                                                            
  __FanControl commands with examples:__                      
                                                                                
  `fancontrol                   # Show FanControl status`                         
  `fancontrol help              # Help menu`                                      
  `sudo fancontrol start        # Start FanControl`                               
  `sudo fancontrol stop         # Stop FanControl`                                
  `sudo fancontrol min_temp 48  # Min temp threshold`                             
  `sudo fancontrol max_temp 81  # Max temp threshold - Limit is 90°C`             
  `sudo fancontrol min 0        # Min fan speed %`                                
  `sudo fancontrol max 100      # Max fan speed %`                                
  `sudo fancontrol step_up 20   # Fan step-up %`                                 
  `sudo fancontrol step_down 1  # Fan step-down %`                                
  `sudo fancontrol poll 2       # FanControl polling rate in seconds (1 to 10s)`  
  `sudo fancontrol monitor      # Toggle on/off live monitoring in terminal`      
  `sudo fancontrol startup      # Copy or Remove fancontrol.conf at: /etc/init/`
  <br><br>
                                                                                                                  
  __GPUControl commands with examples:__                                       
                                                                                                                  
  `gpucontrol                     # Show current GPU info and frequency`                                            
  `gpucontrol help                # Show this help menu`
  `gpucontrol monitor             # Monitor GPU clockspeed in real-time.`
  `sudo gpucontrol restore        # Restore GPU max frequency to original value`                                    
  `sudo gpucontrol 800            # Set GPU max frequency to 800 MHz`
  `sudo gpucontrol startup        # Enable or disable GPUControl on startup`
  <br><br>
                                                                                                                    
  __SleepControl commands with examples:__                                      
                                                                                                                    
  `sleepcontrol                       # Show SleepControl status`                                                
  `sleepcontrol help                  # Help menu`                                                                   
  `sleepcontrol monitor               # Monitor sleepcontrol's log in realtime (ctrl-c to exit)`                     
  `sleepcontrol powerd                # Monitor powerd.LATEST log in realtime (ctrl-c to exit)`                     
  `sudo sleepcontrol start            # Start SleepControl`                                                           
  `sudo sleepcontrol stop             # Stop SleepControl`                                                           
  `sudo sleepcontrol battery 3 7 12   # When idle, display dims in 3m -> timeout in 7m -> sleeps in 12m on battery`   
  `sudo sleepcontrol power 5 15 30    # When idle, display dims in 5m -> timeout -> 15m -> sleeps in 30m on power`  
  `sudo sleepcontrol battery audio 0  # Disable audio detection on battery; sleep can occur during media playback`   
  `sudo sleepcontrol power audio 1    # Enable audio detection on power; delaying sleep until audio is stopped`
  `sudo sleepcontrol mode freeze      # Suspend mode to freeze.`
  `sudo sleepcontrol startup          # Copy or Remove sleepcontrol.conf at: /etc/init/`     

<br><br><br><br>

__How It Works:__

<br>

*PowerControl:*

- Uses ARM, AMD, and Intel's max_perf_pct for easy user control.
- Pairs user adjustable max_perf_pct and thermal0 temp sensor to create a user adjustable clockspeed-temperature curve. 
- If $min_temp threshold is below a certain point, the CPU will be able to reach max_perf_pct of its speed.
- The closer the CPU approaches $max_temp, the closer it is to min_perf_pct.
- PowerControl will always be stringent regarding thermals and performance versus native behavior.
- Editable clockspeed ramp-up and ramp-down feature; emulating modern AMD thermal behavior for Intel + ARM.
- Alter the clockspeed-temperature curve to be more aggressive/passive using hotzone variable.
<br>

*BatteryControl:*

- Uses ectool's chargecontrol to toggle between normal or idle.
- Check's ectool usbpdpower to identify which charge port is being used
- Recommend turning off adatpive charging in ChromeOS to avoid notification spam.
- Check's BAT0/capacity to measure when to toggle ectool's chargecontrol.
- ChromeOS reports slightly higher values than what BatteryControl sets the charge limit to.
- Charge limit is preserved during freeze sleep with SleepControl allowing to change sleep type. 

<br>

*FanControl:*

- Uses ectool's fanduty control and autofanctrl for manual and automatic control.
- Pairs fanduty with thermal0 temperature sensor for a user adjustable fan-temperature curve.
- Uses hysteresis formula to attempt a better sounding and performing fan curve than the OEM provides. 
- Uses a kickstart mechanism when fan leaves 0% to enable zero RPM mode for any fan type.
- Default FanControl behavior has aggressive fan ramp-up behavior with a graceful decrease.


<br>

*GPUControl:*

- Identifies the GPU (AMD, Adreno, Mali, and Intel) based on the name of the device's path in /sys/class/
- Limits control to only below the maximum clock speed for safety and with Chromebooks in mind.
- ChromeOS has built-in overclock prevention, so these safety precautions are just extra guardrails.
- Altering GPU clockspeed in real-time is a useful tool to debug performance. 
- Intel GPU's maximum clock speed changed from: /sys/class/drm/card0/gt_max_freq_mhz
- AMD GPU's maximum clockspeed changed from: /sys/class/drm/card0/pp_od_clk_voltage
- Adreno GPU's maximum clockspeed changed from /sys/class/kgsl/kgsl-3d0/max_gpuclk
- Mali GPU's maximum clockspeed changed from: /sys/class/devfreq/mali0/max_freq

<br>


*SleepControl:*

- SleepControl does not send sleep commands to the OS, but simulates activity when idle on a configurable timer. 
- By passively reading powerd.LATEST log, SleepControl monitors when the powerd daemon reports 'User activity stopped'.
- Parsing strings like 'User activity started' or 'User activiting ongoing' tells SleepControl the user is active.
- If 'User activity stopped' is parsed, SleepControl assumes the user is away and sleep timers begin.
- Can turn on or off audio detection to customize sleep during multimedia playback.
- ChromeOS will report 'User activity stopped' after around 20 seconds of inactivity, so the timers won't be exact.
- When idle, SleepControl uses dbus to send an empty input every 4m until interrupted/sleeping with the configurable timer.  
- By using epoch timestamps, SleepControl is able to verify when its simulated inputs are to be ignored.
- Allows user to customize when display can dim, turn off, and delays sleep.
- Requires sleep to be enabled in settings -> power since SleepControl will not send a sleep command to OS; only delay it.

<br>
<br>

*Changelog:*

- 0.1:  `Released BatteryControl.`<br> <br>
- 0.11: `Released PowerControl with CPU performance curve and combined BatteryControl.`<br> <br>
- 0.12: `Added support for AMD and ARM.`<br> <br>
- 0.13: `Added FanControl.`<br> <br>
- 0.14: `Updated BatteryControl to support switching charging ports.`<br> <br>
- 0.15: `Updated UI, added customizing install location, merged config files into one, and added commands.`<br> <br>
- 0.16: `Fixed several syntax errors and improved color coding.`<br> <br>
- 0.17: `Added GPUControl, cleaned up useless code, improved logs, config settings preserved on reinstalling, and fixed syntax errors.`<br> <br>
- 0.18: `Added gpucontrol restore command. Added ability to boot up with desired GPU clockspeed with 120s delay.
AMD GPU support tweaked to allow idle clocks when overriding clockspeed. Added reinstall command for fast updating.
Uninstaller no longer requiring user to reboot to restore GPU clockspeed. Fixed duplicate log entry and other bugs.
Added ramp_up and ramp_down commands for PowerControl CPU scaling speed.
Added stop processes commands and better cleanup when running startup, reinstalling and uninstalling.
Reformatted status for better readability. Added post-install notes for BatteryControl and GPUControl.`<br><br>
- 0.19: `Added SleepControl - control how long ChromeOS can remain idle before sleeping; irrespective of system sleep settings.
Removed Intel Turbo Boost questions from installer but keeping the options to toggle in PowerControl.`<br><br>
- 0.20: `Added dimming feature for SleepControl. Fixed SleepControl not switching between power and battery modes. Fixed some minor typos.
Added delay on startup for SleepControl. Improved audio detection for sleep prevention.`<br><br>
- 0.21: `Added commands for SleepControl to toggle audio detection for battery and power.`<br><br>
- 0.22: `PowerControl gets HOTZONE variable - Allowing non-linear performance scaling until hotzone threshold is reached.
FanControl hysteresis formula improved by adding gradual ramping with asymmetric steps.
BatteryControl simplified; no need to manage $CHARGE_MIN and removed requirement for 'set' argument.` <br><br>
- 0.23: `Improved Hotzone scaling math to be more thermally proactive.
Fixed FanControl from not fully disabling autofanctrl on boot for the first minute or so.`<br><br>
- 0.24: `Changed variable for input to choice then checked if it's populated, else use existing value for INSTALL_DIR.
Added checking versions for latest available and offering reinstall option if it's not up-to-date.
Thanks to DennisLfromGA for implementing these changes.` <br><br>
- 0.25: `Simplified file structure thanks to DennyL's crouton upstart script from 2014. Improved version checking thanks to DennyL. 
Reworked FanControl zero RPM ramp to be more gradual. Improve step-up and step-down algorithm. Renamed fancontrol update command.
Added PowerControl polling command. Made UI more organized.` <br><br>
- 0.26: `Passively cooled device awareness added for FanControl and the installer. 
Added message to make sure sudo is run for commands (excluding status and help).
Thanks again to DennyL for the suggestions!`
- 0.27: `Fixed bug with SleepControl not starting on boot.` <br> <br>
- 0.28: `Fixed bug with GPUControl not applying user-preferred clockspeed on boot and refactored sections. Fixed version script for supporting base 10 values.` <br><br>
- 0.29: `Improved ARM support for BatteryControl, PowerControl, and GPUControl. Removed requirement for entering GPU type and improved kHz conversion in GPUControl.
Shortened arguments for PowerControl and FanControl. Fixed minor errors in SleepControl before its rewrite.` <br><br>
- 0.30: `Fixed logic order for sleepcontrol that caused it to eventually stop working. Added monitor command for sleepcontrol.` <br><br>
- 0.31: `Sleepcontrol simulation thresholds rewritten. Fixed bug with missing stop command for sleepcontrol during uninstall/reinstall. Fixed bug with removing $PID_FILE.lock on stop. Added ability to keep backlit keyboard off during simulated activity. Added powerd monitor command for SleepControl.` <br><br>
- 0.32: `Fixed monitor process syntax so stop commands will work reliably` <br><br>
- 0.33: `Fixed batterycontrol run flag being duplicated. Restore Battery charge control when stopping BatteryControl.` <br><br>
- 0.34: `Added sleepcontrol mode command to alter suspend modes and apply on boot; preserving batterycontrol logic during sleep.
Fixed config loading logic in sleepcontrol so settings update properly. Updated SleepControl battery detection using powerd.LATEST for better compatibility.
Added prompt in installer to set suspend mode to freeze. ` <br><br>
- 0.35: `Added lid sleep logic for independent sleep rules when closing lid on battery and power. Added external display awareness. Added support for mem_sleep to be changed to s2idle for improved ectool control.
Fixed bug with SleepControl altering display brightness incorrectly. Fixed minor syntax issues.` <br><br>
- 0.36: `Removed Installer prompts to enable freeze suspend. Fixed syntax errors.` <br><br>
- 0.37: `Added brightness restore safeguard logic to reliably restore display brightness. Split up 'user activity ongoing'
powerd keyword. Removed old code and repetitive log entries.` <br><br>
- 0.38: `Fixed brightness scaling logic.  Removed turbo boost question from installer - PowerControl can handle the heat.` <br><br>
- 0.39: `Added startup_all, start_all commands. Fixed PID cleanup.` <br><br>
- 0.40: `Implemented deep sleep enforcement logic; enabling Chromebook to dynamically switch between s2idle and deep sleep depending on power states.
This enables BatteryControl logic to remain active while plugged in.` <br><br>
- 0.41: `Rewrote BatteryControl with dynamic battery path detection. Added monitor command to BatteryControl. Rewrote monitor commands for PowerControl and FanControl.
FanControl kick start is a bit more graceful.` <br><br>
- 0.42: `Replaced cat logic with read for lower cpu usage on monitoring loops. Thanks to Denny and Saragon for great ideas.` <br><br>
- 0.43: `Fixed fancontrol poll rates from not updating properly. Loosened sleepcontrol audio detection and simulated activity parameters.
Moved disable_dark_suspend=0 logic into read section. Cleaned up sending fake activity script to be bit more aggressive. Relaxed zero rpm kickstart.
Added back verbose logging (To do: Plan on implementing log levels recommend by Saragon).` <br><br>
- 0.44: `Reworked SleepControl simulated activity timestamp comparison logic to work reliably` <br><br>
- 0.45: `Cleaned up FanControl loop logic. Fixed logic loophole in batterycontrol to misreport charge status. Added not-charging description in battery control monitor.
Implemented mem sleep logic in sleepcontrol to avoid s2idle. Fixed fancontrol.conf file from respawning. Added lid state detection with loop logic to re-suspend machine upon wakeup from power changes while lid sleep is on.` <br><br>
- 0.46: `Fixed power switching loop. Removed mem sleep commands due to ARM incompatiblity. Added previous install path to be autofilled when reinstalling.` <br><br>
- 0.47: `Implemented reliable simulation activity, removed race conditions, and fixed bugs for SleepControl. Added back SleepControl prompts in Installer.
Added display and keyboard backlight restore in Installer when restarting powerd. Lowered FanControl aggressiveness above 50% fan speed.` <br><br>
- 0.48: `Fixed brightness saving issues for display and keyboard` <br><br>
- 0.49: `Added proper CPU restore logic when stopping PowerControl. Fixed bug where display brightness can be saved when lid is closed` <br><br>
- 0.50: `Relaxed FanControl default settings. Fixed lid sleep bug. Fixed SleepControl visual timer bug. Fixed bug with redownloading scripts. Improved FanControl and BatteryControl loop resets. Fixed typo with GPUControl startup. Added 'mon' shortcut for monitor commands.` <br><br>
- 0.51: `Replaced $date commands with printf and EPOCHSECONDS to reduce CPU usage. Created seperate Reinstall.sh file to fix harmless reinstall errors (caused by having reinstall commands inside PowerControl itself). Fixed sleepcontrol loop ending on power state change.` <br><br>
- 0.52: `GUI app created for Crostini and Chard. Config file is now located in ~/MyFiles/Downloads/.` <br><br>
- 0.53: `Streamlined GUI app and fixed numerous bugs with it. Added usage command for BatteryControl. Added monitor command for GPUControl. GPUControl now runs in a loop for dynamic config adjustments. Startup commands can now be altered with GUI app.` <br><br>
- 0.54: `Fixed fancontrol zero rpm mode issue when adjusting min_fan speed while at zero rpm.` <br><br>
- 0.55: `Fixed sleepcontrol not saving values due to moving config file to noexec mount for GUI. Simplified installer. ` <br><br>
- 0.56: `Fixed GPUControl on startup not working. Removed sudo error warning on status pages.` <br><br>
__Acknowledgements:__

- Thanks to WesBosch for helping me learn to make an installer:
  https://github.com/WesBosch
  
- Thanks to DennisLfromGA for showing me how to enable sudo on crosh, testing out PowerControl, finding bugs, implementing fixes, and providing  many great suggestions:
https://github.com/DennisLfromGA

- Saragon making great suggestions:
https://github.com/Saragon4005
<br>

__Support:__

- Feel free to post any issues or on the ChromeOS discord - there is a thread dedicated to ChromeOS_PowerControl: https://discord.gg/chromeos

```
cat <<'EOF' | sudo tee /usr/share/applications/powercontrol-gui.desktop > /dev/null
[Desktop Entry]
Exec=/usr/bin/powercontrol-gui
StartupNotify=true
Terminal=false
Icon=ChromeOS_PowerControl
Type=Application
Categories=Utility
Version=1.0
EOF

sudo curl -Ls \
https://raw.githubusercontent.com/shadowed1/ChromeOS_PowerControl/main/ChromeOS_PowerControl.png \
-o /usr/share/icons/hicolor/256x256/apps/ChromeOS_PowerControl.png
```
  
