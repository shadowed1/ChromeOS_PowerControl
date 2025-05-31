#!/bin/bash

CONFIG_FILE="$HOME/.batterycontrol_config"
CHARGER_PATH="/sys/class/power_supply/CROS_USBPD_CHARGER0/online"
BATTERY_PATH="/sys/class/power_supply/BAT0/capacity"
RUN_FLAG="$HOME/.batterycontrol_enabled"

# Charge Values - Values reported in ChromeOS may be ~3% higher than set here.
DEFAULT_CHARGE_MAX=77
DEFAULT_CHARGE_MIN=74

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        CHARGE_MAX=$DEFAULT_CHARGE_MAX
        CHARGE_MIN=$DEFAULT_CHARGE_MIN
    fi
}

save_config() {
    echo "CHARGE_MAX=$CHARGE_MAX" > "$CONFIG_FILE"
    echo "CHARGE_MIN=$CHARGE_MIN" >> "$CONFIG_FILE"
}

set_thresholds() {
    if ! [[ "$1" =~ ^[0-9]+$ && "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: Both thresholds must be integers."
        exit 1
    fi
    if [ "$1" -gt 100 ] || [ "$2" -lt 10 ]; then
        echo "Error: CHARGE_MAX cannot be more than 100, and CHARGE_MIN cannot be less than 10."
        exit 1
    fi

    if [ "$2" -ge "$1" ]; then
        echo "Error: CHARGE_MIN must be less than CHARGE_MAX."
        exit 1
    fi
    
    echo "Battery Charge Status: MAX=$1, MIN=$2"
    CHARGE_MAX=$1
    CHARGE_MIN=$2
    save_config
}

toggle_script() {
    if [ "$1" == "on" ]; then
        touch "$RUN_FLAG"
        echo "Script enabled."
    elif [ "$1" == "off" ]; then
        rm -f "$RUN_FLAG"
        echo " disabled."
    fi
}

if [ "$1" == "set" ]; then
    set_thresholds "$2" "$3"
    exit 0
elif [ "$1" == "toggle" ]; then
    toggle_script "$2"
    exit 0
fi

load_config

while true; do
    if [ ! -f "$RUN_FLAG" ]; then
        sleep 120
        continue
    fi

    if [ -f "$BATTERY_PATH" ]; then
        CHARGE=$(cat "$BATTERY_PATH" 2>/dev/null)
    else
        sleep 120
        continue
    fi

    if [ -f "$CHARGER_PATH" ]; then
        AC_ON=$(cat "$CHARGER_PATH" 2>/dev/null)
    else
        sleep 120
        continue
    fi

    if [ "$AC_ON" -eq 1 ]; then
        if [ "$CHARGE" -ge "$CHARGE_MAX" ]; then
            sudo ectool chargecontrol idle >/dev/null 2>&1
        elif [ "$CHARGE" -le "$CHARGE_MIN" ]; then
            sudo ectool chargecontrol normal >/dev/null 2>&1
        fi
    else
        sudo ectool chargecontrol normal >/dev/null 2>&1
    fi

    sleep 120
done
