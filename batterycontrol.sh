#!/bin/bash
 
CHARGER_PATH="/sys/class/power_supply/CROS_USBPD_CHARGER0/online"
BATTERY_PATH="/sys/class/power_supply/BAT0/capacity"

while true; do
    if [ -f "$BATTERY_PATH" ]; then
        CHARGE=$(cat "$BATTERY_PATH" 2>/dev/null)
    else
        echo "Battery capacity not found." >/dev/null
        sleep 120
        continue
    fi

    if [ -f "$CHARGER_PATH" ]; then
        AC_ON=$(cat "$CHARGER_PATH" 2>/dev/null)
    else
        echo "Charging status not found." >/dev/null
        sleep 120
        continue
    fi

    if [ "$AC_ON" -eq 1 ]; then
        if [ "$CHARGE" -ge 77 ]; then
            sudo ectool chargecontrol idle >/dev/null 2>&1
        elif [ "$CHARGE" -le 74 ]; then
            sudo ectool chargecontrol normal >/dev/null 2>&1
        fi
    else
        sudo ectool chargecontrol normal >/dev/null 2>&1
    fi

    sleep 120
done
