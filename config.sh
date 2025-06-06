#!/bin/bash

# Set installation directory if not already set
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"
fi

# Battery Control Settings
DEFAULT_CHARGE_MAX=77
DEFAULT_CHARGE_MIN=74
CHARGE_MAX="${CHARGE_MAX:-$DEFAULT_CHARGE_MAX}"
CHARGE_MIN="${CHARGE_MIN:-$DEFAULT_CHARGE_MIN}"

# Fan Control Settings
DEFAULT_FAN_MIN_TEMP=48   # Minimum fan control temperature
DEFAULT_FAN_MAX_TEMP=81   # Maximum fan control temperature
DEFAULT_MIN_FAN=0         # Minimum fan speed
DEFAULT_MAX_FAN=100       # Maximum fan speed
DEFAULT_SLEEP_INTERVAL=3
DEFAULT_STEP_UP=20
DEFAULT_STEP_DOWN=1

# Power Control Settings
DEFAULT_POWER_MIN_TEMP=60  # Minimum temperature for CPU power control
DEFAULT_POWER_MAX_TEMP=86  # Maximum temperature for CPU power control
DEFAULT_MIN_PERF_PCT=50    # Minimum performance percentage
DEFAULT_MAX_PERF_PCT=100   # Maximum performance percentage
MAX_TEMP_LIMIT=90          # Maximum allowable temperature limit

# Default values for all temperature and performance settings
FAN_MIN_TEMP="${FAN_MIN_TEMP:-$DEFAULT_FAN_MIN_TEMP}"
FAN_MAX_TEMP="${FAN_MAX_TEMP:-$DEFAULT_FAN_MAX_TEMP}"
MIN_FAN="${MIN_FAN:-$DEFAULT_MIN_FAN}"
MAX_FAN="${MAX_FAN:-$DEFAULT_MAX_FAN}"
SLEEP_INTERVAL="${SLEEP_INTERVAL:-$DEFAULT_SLEEP_INTERVAL}"
STEP_UP="${STEP_UP:-$DEFAULT_STEP_UP}"
STEP_DOWN="${STEP_DOWN:-$DEFAULT_STEP_DOWN}"

POWER_MIN_TEMP="${POWER_MIN_TEMP:-$DEFAULT_POWER_MIN_TEMP}"
POWER_MAX_TEMP="${POWER_MAX_TEMP:-$DEFAULT_POWER_MAX_TEMP}"
MIN_PERF_PCT="${MIN_PERF_PCT:-$DEFAULT_MIN_PERF_PCT}"
MAX_PERF_PCT="${MAX_PERF_PCT:-$DEFAULT_MAX_PERF_PCT}"

# Set paths for battery and temperature monitoring
CHARGER_PATH="/sys/class/power_supply/CROS_USBPD_CHARGER0/online"
BATTERY_PATH="/sys/class/power_supply/BAT0/capacity"
ZONE_PATH="/sys/class/thermal/thermal_zone0/temp"

BATTERY_LOG="/var/log/batterycontrol.log"
POWER_LOG="/var/log/powercontrol.log"
FAN_LOG="/var/log/fancontrol.log"

RUN_FLAG_FAN="$INSTALL_DIR/.fan_curve_running"
PID_FILE="$INSTALL_DIR/.fancontrol.pid"
MONITOR_PID_FILE_FAN="$INSTALL_DIR/powercontrol_tail_fan_monitor.pid"
RUN_FLAG="$INSTALL_DIR/.powercontrol_enabled"
PID_FILE_POWER="$INSTALL_DIR/.powercontrol_pid"
NO_TURBO_BACKUP="$INSTALL_DIR/.no_turbo_backup"

USER_HOME="/home/chronos"

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || echo "unknown")
PERF_PATH=""
TURBO_PATH=""
IS_AMD=0
IS_INTEL=0
IS_ARM=0

detect_cpu_type() {
    case "$CPU_VENDOR" in
        GenuineIntel)
            IS_INTEL=1
            if [ -f "/sys/devices/system/cpu/intel_pstate/max_perf_pct" ]; then
                PERF_PATH="/sys/devices/system/cpu/intel_pstate/max_perf_pct"
                TURBO_PATH="/sys/devices/system/cpu/intel_pstate/no_turbo"
            fi
            ;;
        AuthenticAMD)
            IS_AMD=1
            if [ -f "/sys/devices/system/cpu/amd_pstate/max_perf_pct" ]; then
                PERF_PATH="/sys/devices/system/cpu/amd_pstate/max_perf_pct"
            else
                PERF_PATH="/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
            fi
            ;;
        *)
            IS_ARM=1
            PERF_PATH="/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
            ;;
    esac
}

validate_config() {
    if [ -z "$FAN_MIN_TEMP" ]; then FAN_MIN_TEMP=$DEFAULT_FAN_MIN_TEMP; fi
    if [ -z "$FAN_MAX_TEMP" ]; then FAN_MAX_TEMP=$DEFAULT_FAN_MAX_TEMP; fi
    if [ -z "$POWER_MIN_TEMP" ]; then POWER_MIN_TEMP=$DEFAULT_POWER_MIN_TEMP; fi
    if [ -z "$POWER_MAX_TEMP" ]; then POWER_MAX_TEMP=$DEFAULT_POWER_MAX_TEMP; fi
}

# Load the configuration values (everything controlled here)
load_config() {
    validate_config
    echo "Loading configuration values:"
    echo "Battery Control:"
    echo "  CHARGE_MAX: $CHARGE_MAX"
    echo "  CHARGE_MIN: $CHARGE_MIN"
    echo "Fan Control:"
    echo "  FAN_MIN_TEMP: $FAN_MIN_TEMP"
    echo "  FAN_MAX_TEMP: $FAN_MAX_TEMP"
    echo "  MIN_FAN: $MIN_FAN"
    echo "  MAX_FAN: $MAX_FAN"
    echo "Power Control:"
    echo "  POWER_MIN_TEMP: $POWER_MIN_TEMP"
    echo "  POWER_MAX_TEMP: $POWER_MAX_TEMP"
    echo "  MIN_PERF_PCT: $MIN_PERF_PCT"
    echo "  MAX_PERF_PCT: $MAX_PERF_PCT"
}

# Save config function (no external file used, just script-level variables)
save_config() {
    validate_config
    echo "Saving configuration values:"
    echo "Battery Control:"
    echo "  CHARGE_MAX: $CHARGE_MAX"
    echo "  CHARGE_MIN: $CHARGE_MIN"
    echo "Fan Control:"
    echo "  FAN_MIN_TEMP: $FAN_MIN_TEMP"
    echo "  FAN_MAX_TEMP: $FAN_MAX_TEMP"
    echo "  MIN_FAN: $MIN_FAN"
    echo "  MAX_FAN: $MAX_FAN"
    echo "Power Control:"
    echo "  POWER_MIN_TEMP: $POWER_MIN_TEMP"
    echo "  POWER_MAX_TEMP: $POWER_MAX_TEMP"
    echo "  MIN_PERF_PCT: $MIN_PERF_PCT"
    echo "  MAX_PERF_PCT: $MAX_PERF_PCT"
}

# Exporting variables for use in the system
export USER_HOME
export INSTALL_DIR
export CHARGER_PATH
export BATTERY_PATH
export ZONE_PATH
export RUN_FLAG_FAN
export PID_FILE
export MONITOR_PID_FILE_FAN
export RUN_FLAG
export PID_FILE_POWER
export NO_TURBO_BACKUP
export PERF_PATH
export TURBO_PATH
export IS_AMD
export IS_INTEL
export IS_ARM
export FAN_MIN_TEMP
export FAN_MAX_TEMP
export MIN_FAN
export MAX_FAN
export SLEEP_INTERVAL
export STEP_UP
export STEP_DOWN
export POWER_MIN_TEMP
export POWER_MAX_TEMP
export MIN_PERF_PCT
export MAX_PERF_PCT
export BATTERY_LOG
export POWER_LOG
export FAN_LOG

# Load the configuration values
load_config
