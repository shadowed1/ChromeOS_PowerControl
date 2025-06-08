###############################################################################################################

# PowerControl
MAX_TEMP=85
MAX_PERF_PCT=100
MIN_TEMP=60
MIN_PERF_PCT=40

###############################################################################################################

# BatteryControl:
CHARGE_MAX=77
CHARGE_MIN=74

###############################################################################################################

# FanControl:
FAN_MIN_TEMP=46
FAN_MAX_TEMP=80
MIN_FAN=0
MAX_FAN=100
SLEEP_INTERVAL=3
STEP_UP=20
STEP_DOWN=1

###############################################################################################################

# Startup Flags
STARTUP_BATTERYCONTROL=1
STARTUP_FANCONTROL=1
STARTUP_POWERCONTROL=1

###############################################################################################################

if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"
fi
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
# System Paths
BATTERY_PATH="/sys/class/power_supply/BAT0/capacity"
BATTERY_STATUS_PATH="/sys/class/power_supply/BAT0/status"
ZONE_PATH="/sys/class/thermal/thermal_zone0/temp"
export STARTUP_BATTERYCONTROL
export STARTUP_FANCONTROL
export STARTUP_POWERCONTROL
