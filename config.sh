# Configuration file for PowerControl, BatteryControl, and FanControl

# Installation Directory
INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"

# Default values for Battery Control
DEFAULT_CHARGE_MAX=77
DEFAULT_CHARGE_MIN=74

# Paths for Battery Control
CHARGER_PATH="/sys/class/power_supply/CROS_USBPD_CHARGER0/online"
BATTERY_PATH="/sys/class/power_supply/BAT0/capacity"
BATTERY_CONFIG_FILE="$INSTALL_DIR/.batterycontrol_config"

# Default values for Fan Control
DEFAULT_MIN_TEMP=48
DEFAULT_MAX_TEMP=81
DEFAULT_MIN_FAN=0
DEFAULT_MAX_FAN=100
DEFAULT_SLEEP_INTERVAL=3
DEFAULT_STEP_UP=20
DEFAULT_STEP_DOWN=1

# Paths for Fan Control
ZONE_PATH="/sys/class/thermal/thermal_zone0/temp"
RUN_FLAG_FAN="/tmp/.fan_curve_running"
PID_FILE_FAN="/tmp/.fan_curve_pid"
MONITOR_PID_FILE_FAN="/tmp/powercontrol_tail_fan_monitor.pid"

# Running flags and PID files for PowerControl
USER_HOME="/home/chronos"
RUN_FLAG="$INSTALL_DIR/.powercontrol_enabled"
PID_FILE="$INSTALL_DIR/.powercontrol_pid"
NO_TURBO_BACKUP="$INSTALL_DIR/.no_turbo_backup"

# CPU Vendor Detection and Performance Paths
CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || echo "unknown")
PERF_PATH=""
TURBO_PATH=""
IS_AMD=0
IS_INTEL=0
IS_ARM=0

# Default PowerControl Thresholds and Performance Percentages
DEFAULT_MAX_TEMP=86
DEFAULT_MAX_PERF_PCT=100
DEFAULT_MIN_TEMP=60
DEFAULT_MIN_PERF_PCT=50
MAX_TEMP_LIMIT=90

# Load Configurations from file
MAX_TEMP=""
MAX_PERF_PCT=""
MIN_TEMP=""
MIN_PERF_PCT=""

# Load Battery and Fan Configurations from respective config files
load_config() {
    # Load Battery Control configuration
    if [ -f "$BATTERY_CONFIG_FILE" ]; then
        source "$BATTERY_CONFIG_FILE"
    else
        # Use default values if configuration file is missing
        CHARGE_MAX=$DEFAULT_CHARGE_MAX
        CHARGE_MIN=$DEFAULT_CHARGE_MIN
        save_battery_config
    fi

    # Load Fan Control configuration
    if [ -f "$INSTALL_DIR/.fancontrol_config" ]; then
        source "$INSTALL_DIR/.fancontrol_config"
    else
        # Use default values if configuration file is missing
        MIN_TEMP=$DEFAULT_MIN_TEMP
        MAX_TEMP=$DEFAULT_MAX_TEMP
        MIN_FAN=$DEFAULT_MIN_FAN
        MAX_FAN=$DEFAULT_MAX_FAN
        SLEEP_INTERVAL=$DEFAULT_SLEEP_INTERVAL
        STEP_UP=$DEFAULT_STEP_UP
        STEP_DOWN=$DEFAULT_STEP_DOWN
        save_fan_config
    fi

    # Load PowerControl configuration from file
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        MAX_TEMP=$DEFAULT_MAX_TEMP
        MAX_PERF_PCT=$DEFAULT_MAX_PERF_PCT
        MIN_TEMP=$DEFAULT_MIN_TEMP
        MIN_PERF_PCT=$DEFAULT_MIN_PERF_PCT
        save_config
    fi
}

# Save Battery Control configuration
save_battery_config() {
    echo "CHARGE_MAX=${CHARGE_MAX:-$DEFAULT_CHARGE_MAX}" > "$BATTERY_CONFIG_FILE"
    echo "CHARGE_MIN=${CHARGE_MIN:-$DEFAULT_CHARGE_MIN}" >> "$BATTERY_CONFIG_FILE"
}

# Save Fan Control configuration
save_fan_config() {
    echo "MIN_TEMP=${MIN_TEMP:-$DEFAULT_MIN_TEMP}" > "$INSTALL_DIR/.fancontrol_config"
    echo "MAX_TEMP=${MAX_TEMP:-$DEFAULT_MAX_TEMP}" >> "$INSTALL_DIR/.fancontrol_config"
    echo "MIN_FAN=${MIN_FAN:-$DEFAULT_MIN_FAN}" >> "$INSTALL_DIR/.fancontrol_config"
    echo "MAX_FAN=${MAX_FAN:-$DEFAULT_MAX_FAN}" >> "$INSTALL_DIR/.fancontrol_config"
    echo "SLEEP_INTERVAL=${SLEEP_INTERVAL:-$DEFAULT_SLEEP_INTERVAL}" >> "$INSTALL_DIR/.fancontrol_config"
    echo "STEP_UP=${STEP_UP:-$DEFAULT_STEP_UP}" >> "$INSTALL_DIR/.fancontrol_config"
    echo "STEP_DOWN=${STEP_DOWN:-$DEFAULT_STEP_DOWN}" >> "$INSTALL_DIR/.fancontrol_config"
}

# Save PowerControl configuration
save_config() {
    validate_config
    echo "MAX_TEMP=${MAX_TEMP:-$DEFAULT_MAX_TEMP}" > "$CONFIG_FILE"
    echo "MAX_PERF_PCT=${MAX_PERF_PCT:-$DEFAULT_MAX_PERF_PCT}" >> "$CONFIG_FILE"
    echo "MIN_TEMP=${MIN_TEMP:-$DEFAULT_MIN_TEMP}" >> "$CONFIG_FILE"
    echo "MIN_PERF_PCT=${MIN_PERF_PCT:-$DEFAULT_MIN_PERF_PCT}" >> "$CONFIG_FILE"
}

# Validate configurations to ensure no missing values
validate_config() {
    if [[ -z "$MAX_TEMP" ]]; then MAX_TEMP=$DEFAULT_MAX_TEMP; fi
    if [[ -z "$MAX_PERF_PCT" ]]; then MAX_PERF_PCT=$DEFAULT_MAX_PERF_PCT; fi
    if [[ -z "$MIN_TEMP" ]]; then MIN_TEMP=$DEFAULT_MIN_TEMP; fi
    if [[ -z "$MIN_PERF_PCT" ]]; then MIN_PERF_PCT=$DEFAULT_MIN_PERF_PCT; fi
}

# CPU Vendor detection and power paths
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

# Export variables for usage
export USER_HOME
export CONFIG_FILE
export RUN_FLAG
export PID_FILE
export NO_TURBO_BACKUP
export PERF_PATH
export TURBO_PATH
export IS_AMD
export IS_INTEL
export IS_ARM
export MAX_TEMP
export MIN_TEMP
export MAX_PERF_PCT
export MIN_PERF_PCT
