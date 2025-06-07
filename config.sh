#!/bin/bash

# POWERCONTROL
MAX_TEMP=86
MAX_PERF_PCT=100
MIN_TEMP=60
MIN_PERF_PCT=50

# BATTERYCONTROL
CHARGE_MAX=77
CHARGE_MIN=74

# FANCONTROL
FAN_MIN_TEMP=48
FAN_MAX_TEMP=81
FAN_MIN=0
FAN_MAX=100
FAN_SLEEP_INTERVAL=3
FAN_STEP_UP=20
FAN_STEP_DOWN=1

# Service startup flags
STARTUP_BATTERYCONTROL=1
STARTUP_FANCONTROL=1
STARTUP_POWERCONTROL=1

# CPU Information & Control
PERF_PATH=""
TURBO_PATH=""
IS_AMD=0
IS_INTEL=0
IS_ARM=0

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

# PID Files
PID_FILE_BATTERY="$INSTALL_DIR/.batterycontrol_pid"
PID_FILE_POWER="$INSTALL_DIR/.powercontrol_pid"
PID_FILE_FAN="$INSTALL_DIR/.fan_curve_pid"
MONITOR_POWER_PID_FILE="$INSTALL_DIR/.powercontrol_tail_fan_monitor.pid"
MONITOR_FAN_PID_FILE="$INSTALL_DIR/.fancontrol_tail_fan_monitor.pid"

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

# Load the configuration from the variables
load_config() {
    detect_cpu_type
}

# Save the configuration for later
save_config() {
    echo "Saving configuration to $INSTALL_DIR/config.sh..."
    cat <<EOF > "$INSTALL_DIR/config.sh"
# POWERCONTROL
MAX_TEMP=$MAX_TEMP
MAX_PERF_PCT=$MAX_PERF_PCT
MIN_TEMP=$MIN_TEMP
MIN_PERF_PCT=$MIN_PERF_PCT

# BATTERYCONTROL
CHARGE_MAX=$CHARGE_MAX
CHARGE_MIN=$CHARGE_MIN

# FANCONTROL
FAN_MIN_TEMP=$FAN_MIN_TEMP
FAN_MAX_TEMP=$FAN_MAX_TEMP
FAN_MIN=$FAN_MIN
FAN_MAX=$FAN_MAX
FAN_SLEEP_INTERVAL=$FAN_SLEEP_INTERVAL
FAN_STEP_UP=$FAN_STEP_UP
FAN_STEP_DOWN=$FAN_STEP_DOWN

# Service startup flags
STARTUP_BATTERYCONTROL=$STARTUP_BATTERYCONTROL
STARTUP_FANCONTROL=$STARTUP_FANCONTROL
STARTUP_POWERCONTROL=$STARTUP_POWERCONTROL

# CPU Information & Control
PERF_PATH=$PERF_PATH
TURBO_PATH=$TURBO_PATH
IS_AMD=$IS_AMD
IS_INTEL=$IS_INTEL
IS_ARM=$IS_ARM

# Log Files
BATTERY_LOG=$BATTERY_LOG
POWER_LOG=$POWER_LOG
FAN_LOG=$FAN_LOG

# System Paths
CHARGER_PATH=$CHARGER_PATH
BATTERY_PATH=$BATTERY_PATH
ZONE_PATH=$ZONE_PATH

EOF
}

# Export variables for access by other scripts
export INSTALL_DIR
export CHARGE_MAX
export CHARGE_MIN
export FAN_MIN_TEMP
export FAN_MAX_TEMP
export FAN_MIN
export FAN_MAX
export FAN_SLEEP_INTERVAL
export FAN_STEP_UP
export FAN_STEP_DOWN
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
