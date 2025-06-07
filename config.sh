# Default install directory
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"
fi

CHARGE_MAX=77
CHARGE_MIN=74

MAX_TEMP=86
MAX_PERF_PCT=100
MIN_TEMP=60
MIN_PERF_PCT=50

FAN_MIN_TEMP=48
FAN_MAX_TEMP=81
MIN_FAN=0
MAX_FAN=100
SLEEP_INTERVAL=3
STEP_UP=20
STEP_DOWN=1

# Default Settings for Control        

# Service startup flags
STARTUP_BATTERYCONTROL=1
STARTUP_FANCONTROL=1
STARTUP_POWERCONTROL=1

# Log Files
BATTERY_LOG="/var/log/batterycontrol.log"
POWER_LOG="/var/log/powercontrol.log"
FAN_LOG="/var/log/fancontrol.log" 

# System Paths
CHARGER_PATH="/sys/class/power_supply/CROS_USBPD_CHARGER0/online"
BATTERY_PATH="/sys/class/power_supply/BAT0/capacity"
ZONE_PATH="/sys/class/thermal/thermal_zone0/temp"

# Flags for running services
RUN_FLAG_BATTERY="$INSTALL_DIR/.batterycontrol_enabled"
RUN_FLAG_FAN="$INSTALL_DIR/.fan_curve_running"
RUN_FLAG_POWER="$INSTALL_DIR/.powercontrol_enabled"

# PID 
PID_FILE_BATTERY="$INSTALL_DIR/.batterycontrol_pid"
PID_FILE_POWER="$INSTALL_DIR/.powercontrol_pid"
PID_FILE_FAN="$INSTALL_DIR/.fan_curve_pid"


export STARTUP_BATTERYCONTROL
export STARTUP_FANCONTROL
export STARTUP_POWERCONTROL

