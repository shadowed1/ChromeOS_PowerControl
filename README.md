# **ChromeOS Battery Control**

## Limit your Chromebook's battery charging limit to your liking instead of relying on Adaptive Charging or Enterprise Group Policies.

### How to Install - Paste the below command in a Crosh Shell:

## `bash <(curl -s https://raw.githubusercontent.com/shadowed1/ChromeOS_BatteryControl/refs/heads/main/ChromeOS_BatteryControl_Downloader.sh)`

This will download the installer.sh to /home/chronos/ChromeOS_BatteryControl. Open up the VT-2 console command and run:

## `sudo bash ~/tmp/ChromeOS_BatteryControl/installer.sh`

After installing, cd to /usr/local/bin/ and run:
## `sudo bash batterycontrol.sh &` ## to have it run in the background. 
