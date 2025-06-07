#!/bin/bash

# Default install directory
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"
fi

# Default Settings for Control
DEFAULT_CHARGE_MAX=77
DEFAULT_CHARGE_MIN=74
DEFAULT_FAN_MIN_TEMP=48   
DEFAULT_FAN_MAX_TEMP=81   
DEFAULT_MIN_FAN=0         
DEFAULT_MAX_FAN=100       
DEFAULT_SLEEP_INTERVAL=3   
DEFAULT_STEP_UP=20        
DEFAULT_STEP_DOWN=1

DEFAULT_MIN_TEMP=60  
DEFAULT_MAX_TEMP=86  
DEFAULT_MIN_PERF_PCT=50    
DEFAULT_MAX_PERF_PCT=100   
MAX_TEMP_LIMIT=90          

# Service startup flags
STARTUP_BATTERYCONTROL=1
STARTUP_FANCONTROL=1
STARTUP_POWERCONTROL=1

# Set variables from environment or default
CHARGE_MAX="${CHARGE_MAX:-$DEFAULT_CHARGE_MAX}"
CHARGE_MIN="${CHARGE_MIN:-$DEFAULT_CHARGE_MIN}"

FAN_MIN_TEMP="${FAN_MIN_TEMP:-$DEFAULT_FAN_MIN_TEMP}"
FAN_MAX_TEMP="${FAN_MAX_TEMP:-$DEFAULT_FAN_MAX_TEMP}"
MIN_FAN="${MIN_FAN:-$DEFAULT_MIN_FAN}"
MAX_FAN="${MAX_FAN:-$DEFAULT_MAX_FAN}"
SLEEP_INTERVAL="${SLEEP_INTERVAL:-$DEFAULT_SLEEP_INTERVAL}"
STEP_UP="${STEP_UP:-$DEFAULT_STEP_UP}"
STEP_DOWN="${STEP_DOWN:-$DEFAULT_STEP_DOWN}"

MIN_TEMP=${MIN_TEMP:-$DEFAULT_MIN_TEMP}
MAX_TEMP=${MAX_TEMP:-$DEFAULT_MAX_TEMP}
MIN_PERF_PCT=${MIN_PERF_PCT:-$DEFAULT_MIN_PERF_PCT}
MAX_PERF_PCT=${MAX_PERF_PCT:-$DEFAULT_MAX_PERF_PCT}

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

# Monitors


# CPU Information & Control
PERF_PATH=""
TURBO_PATH=""
IS_AMD=0
IS_INTEL=0
IS_ARM=0

# Function to detect CPU type (Intel, AMD, ARM)
detect_cpu_type() {
    if [ -z "$PERF_PATH" ] || [ -z "$TURBO_PATH" ] || [ "$IS_AMD" -eq 0 ] && [ "$IS_INTEL" -eq 0 ] && [ "$IS_ARM" -eq 0 ]; then
        CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || echo "unknown")

        case "$CPU_VENDOR" in
            GenuineIntel)
                IS_INTEL=1
                PERF_PATH="/sys/devices/system/cpu/intel_pstate/max_perf_pct"
                TURBO_PATH="/sys/devices/system/cpu/intel_pstate/no_turbo"
                ;;
            AuthenticAMD)
                IS_AMD=1
                if [ -f "/sys/devices/system/cpu/amd_pstate/max_perf_pct" ]; then
                    PERF_PATH="/sys/devices/system/cpu/amd_pstate/max_perf_pct"
                else
                    PERF_PATH="/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
                fi
                TURBO_PATH=""
                ;;
            *)
                IS_ARM=1
                PERF_PATH="/sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
                TURBO_PATH=""
                ;;
        esac
    fi
}

# Validate configuration variables
validate_config() {
    if [ -z "$FAN_MIN_TEMP" ]; then FAN_MIN_TEMP=$DEFAULT_FAN_MIN_TEMP; fi
    if [ -z "$FAN_MAX_TEMP" ]; then FAN_MAX_TEMP=$DEFAULT_FAN_MAX_TEMP; fi
    if [ -z "$MIN_TEMP" ]; then MIN_TEMP=$DEFAULT_MIN_TEMP; fi
    if [ -z "$MAX_TEMP" ]; then MAX_TEMP=$DEFAULT_MAX_TEMP; fi
}

# Load the configuration from the variables
load_config() {
    detect_cpu_type
    validate_config
}

# Save the configuration for later
save_config() {
    validate_config  

    if [ "$MIN_TEMP" != "$DEFAULT_MIN_TEMP" ]; then
        sed -i "s/^DEFAULT_MIN_TEMP=.*/DEFAULT_MIN_TEMP=$MIN_TEMP/" "$INSTALL_DIR/config.sh"
    fi
    if [ "$MAX_TEMP" != "$DEFAULT_MAX_TEMP" ]; then
        sed -i "s/^DEFAULT_MAX_TEMP=.*/DEFAULT_MAX_TEMP=$MAX_TEMP/" "$INSTALL_DIR/config.sh"
    fi
    if [ "$MIN_PERF_PCT" != "$DEFAULT_MIN_PERF_PCT" ]; then
        sed -i "s/^DEFAULT_MIN_PERF_PCT=.*/DEFAULT_MIN_PERF_PCT=$MIN_PERF_PCT/" "$INSTALL_DIR/config.sh"
    fi
    if [ "$MAX_PERF_PCT" != "$DEFAULT_MAX_PERF_PCT" ]; then
        sed -i "s/^DEFAULT_MAX_PERF_PCT=.*/DEFAULT_MAX_PERF_PCT=$MAX_PERF_PCT/" "$INSTALL_DIR/config.sh"
    fi

    echo "Configuration saved to $INSTALL_DIR/config.sh"
}

# Export variables for access by other scripts
export INSTALL_DIR
export CHARGE_MAX
export CHARGE_MIN
export FAN_MIN_TEMP
export FAN_MAX_TEMP
export MIN_FAN
export MAX_FAN
export SLEEP_INTERVAL
export STEP_UP
export STEP_DOWN
export MIN_TEMP
export MAX_TEMP
export MIN_PERF_PCT
export MAX_PERF_PCT
export BATTERY_LOG
export POWER_LOG
export FAN_LOG
export CHARGER_PATH
export BATTERY_PATH
export ZONE_PATH
export RUN_FLAG_BATTERY
export RUN_FLAG_FAN
export RUN_FLAG_POWER
export PERF_PATH
export TURBO_PATH
export IS_AMD
export IS_INTEL
export IS_ARM

# For configuring services startup status
export STARTUP_BATTERYCONTROL
export STARTUP_FANCONTROL
export STARTUP_POWERCONTROL

# Load the configuration
load_config
