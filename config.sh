if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"
fi

DEFAULT_CHARGE_MAX=77
DEFAULT_CHARGE_MIN=74

CHARGER_PATH="/sys/class/power_supply/CROS_USBPD_CHARGER0/online"
BATTERY_PATH="/sys/class/power_supply/BAT0/capacity"
BATTERY_CONFIG_FILE="$INSTALL_DIR/.batterycontrol_config"

# Fancontrol defaults (prefixed FAN_)
DEFAULT_FAN_MIN_TEMP=48
DEFAULT_FAN_MAX_TEMP=81
DEFAULT_FAN_MIN_FAN=0
DEFAULT_FAN_MAX_FAN=100
DEFAULT_FAN_SLEEP_INTERVAL=3
DEFAULT_FAN_STEP_UP=20
DEFAULT_FAN_STEP_DOWN=1

ZONE_PATH="/sys/class/thermal/thermal_zone0/temp"
RUN_FLAG_FAN="$INSTALL_DIR/.fan_curve_running"
PID_FILE_FAN="$INSTALL_DIR/.fancontrol.pid"
MONITOR_PID_FILE_FAN="$INSTALL_DIR/powercontrol_tail_fan_monitor.pid"

# Powercontrol defaults (prefixed POWER_)
DEFAULT_POWER_MIN_TEMP=60
DEFAULT_POWER_MAX_TEMP=86
DEFAULT_POWER_MIN_PERF_PCT=50
DEFAULT_POWER_MAX_PERF_PCT=100
MAX_TEMP_LIMIT=90

USER_HOME="/home/chronos"
RUN_FLAG="$INSTALL_DIR/.powercontrol_enabled"
PID_FILE_POWER="$INSTALL_DIR/.powercontrol_pid"
NO_TURBO_BACKUP="$INSTALL_DIR/.no_turbo_backup"

CPU_VENDOR=$(grep -m1 'vendor_id' /proc/cpuinfo | awk '{print $3}' || echo "unknown")
PERF_PATH=""
TURBO_PATH=""
IS_AMD=0
IS_INTEL=0
IS_ARM=0

# Fancontrol variables
FAN_MIN_TEMP=""
FAN_MAX_TEMP=""
FAN_MIN_FAN=""
FAN_MAX_FAN=""
FAN_SLEEP_INTERVAL=""
FAN_STEP_UP=""
FAN_STEP_DOWN=""

# Powercontrol variables
POWER_MAX_TEMP=""
POWER_MAX_PERF_PCT=""
POWER_MIN_TEMP=""
POWER_MIN_PERF_PCT=""

load_config() {
    # Load Battery Control configuration
    if [ -f "$BATTERY_CONFIG_FILE" ]; then
        source "$BATTERY_CONFIG_FILE"
    else
        CHARGE_MAX=$DEFAULT_CHARGE_MAX
        CHARGE_MIN=$DEFAULT_CHARGE_MIN
        save_battery_config
    fi

    load_fan_config
    load_power_config

    validate_power_config
}

load_fan_config() {
    if [ -f "$INSTALL_DIR/.fancontrol_config" ]; then
        source "$INSTALL_DIR/.fancontrol_config"
    else
        FAN_MIN_TEMP=$DEFAULT_FAN_MIN_TEMP
        FAN_MAX_TEMP=$DEFAULT_FAN_MAX_TEMP
        FAN_MIN_FAN=$DEFAULT_FAN_MIN_FAN
        FAN_MAX_FAN=$DEFAULT_FAN_MAX_FAN
        FAN_SLEEP_INTERVAL=$DEFAULT_FAN_SLEEP_INTERVAL
        FAN_STEP_UP=$DEFAULT_FAN_STEP_UP
        FAN_STEP_DOWN=$DEFAULT_FAN_STEP_DOWN
        save_fan_config
    fi
}

load_power_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        POWER_MAX_TEMP=$DEFAULT_POWER_MAX_TEMP
        POWER_MAX_PERF_PCT=$DEFAULT_POWER_MAX_PERF_PCT
        POWER_MIN_TEMP=$DEFAULT_POWER_MIN_TEMP
        POWER_MIN_PERF_PCT=$DEFAULT_POWER_MIN_PERF_PCT
        save_power_config
    fi
}

save_battery_config() {
    echo "CHARGE_MAX=${CHARGE_MAX:-$DEFAULT_CHARGE_MAX}" > "$BATTERY_CONFIG_FILE"
    echo "CHARGE_MIN=${CHARGE_MIN:-$DEFAULT_CHARGE_MIN}" >> "$BATTERY_CONFIG_FILE"
}

save_fan_config() {
    echo "FAN_MIN_TEMP=${FAN_MIN_TEMP:-$DEFAULT_FAN_MIN_TEMP}" > "$INSTALL_DIR/.fancontrol_config"
    echo "FAN_MAX_TEMP=${FAN_MAX_TEMP:-$DEFAULT_FAN_MAX_TEMP}" >> "$INSTALL_DIR/.fancontrol_config"
    echo "FAN_MIN_FAN=${FAN_MIN_FAN:-$DEFAULT_FAN_MIN_FAN}" >> "$INSTALL_DIR/.fancontrol_config"
    echo "FAN_MAX_FAN=${FAN_MAX_FAN:-$DEFAULT_FAN_MAX_FAN}" >> "$INSTALL_DIR/.fancontrol_config"
    echo "FAN_SLEEP_INTERVAL=${FAN_SLEEP_INTERVAL:-$DEFAULT_FAN_SLEEP_INTERVAL}" >> "$INSTALL_DIR/.fancontrol_config"
    echo "FAN_STEP_UP=${FAN_STEP_UP:-$DEFAULT_FAN_STEP_UP}" >> "$INSTALL_DIR/.fancontrol_config"
    echo "FAN_STEP_DOWN=${FAN_STEP_DOWN:-$DEFAULT_FAN_STEP_DOWN}" >> "$INSTALL_DIR/.fancontrol_config"
}

save_power_config() {
    validate_power_config
    echo "POWER_MAX_TEMP=${POWER_MAX_TEMP:-$DEFAULT_POWER_MAX_TEMP}" > "$CONFIG_FILE"
    echo "POWER_MAX_PERF_PCT=${POWER_MAX_PERF_PCT:-$DEFAULT_POWER_MAX_PERF_PCT}" >> "$CONFIG_FILE"
    echo "POWER_MIN_TEMP=${POWER_MIN_TEMP:-$DEFAULT_POWER_MIN_TEMP}" >> "$CONFIG_FILE"
    echo "POWER_MIN_PERF_PCT=${POWER_MIN_PERF_PCT:-$DEFAULT_POWER_MIN_PERF_PCT}" >> "$CONFIG_FILE"
}

validate_power_config() {
    if [[ -z "$POWER_MAX_TEMP" ]]; then POWER_MAX_TEMP=$DEFAULT_POWER_MAX_TEMP; fi
    if [[ -z "$POWER_MAX_PERF_PCT" ]]; then POWER_MAX_PERF_PCT=$DEFAULT_POWER_MAX_PERF_PCT; fi
    if [[ -z "$POWER_MIN_TEMP" ]]; then POWER_MIN_TEMP=$DEFAULT_POWER_MIN_TEMP; fi
    if [[ -z "$POWER_MIN_PERF_PCT" ]]; then POWER_MIN_PERF_PCT=$DEFAULT_POWER_MIN_PERF_PCT; fi
}

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

load_config

export USER_HOME
export CONFIG_FILE
export RUN_FLAG
export PID_FILE_POWER
export PID_FILE_FAN
export NO_TURBO_BACKUP
export PERF_PATH
export TURBO_PATH
export IS_AMD
export IS_INTEL
export IS_ARM
export POWER_MAX_TEMP
export POWER_MIN_TEMP
export POWER_MAX_PERF_PCT
export POWER_MIN_PERF_PCT
export FAN_MAX_TEMP
export FAN_MIN_TEMP
export FAN_MAX_FAN
export FAN_MIN_FAN
export FAN_SLEEP_INTERVAL
export FAN_STEP_UP
export FAN_STEP_DOWN
