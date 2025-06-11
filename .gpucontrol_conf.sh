#!/bin/bash

INSTALL_DIR_FILE="/usr/local/bin/.ChromeOS_PowerControl.install_dir"
if [ -f "$INSTALL_DIR_FILE" ]; then
    INSTALL_DIR=$(cat "$INSTALL_DIR_FILE")
else
    INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"
fi

INSTALL_DIR="${INSTALL_DIR%/}"
CONFIG_FILE="$INSTALL_DIR/config.sh"
LOG_FILE="/var/log/gpucontrol.log"
[ -f "$CONFIG_FILE" ] && source "$CONFIG_FILE"


sleep 120

set_amd_freq() {
    local freq="$1"

    if [[ "$freq" -gt "$ORIGINAL_GPU_MAX_FREQ" ]]; then
        echo "GPUControl Error: Requested freq $freq MHz exceeds original max $ORIGINAL_GPU_MAX_FREQ MHz" >> "$LOG_FILE"
        return 1
    fi
    if [[ -z "$PP_OD_FILE" || ! -w "$PP_OD_FILE" ]]; then
        echo "GPUControl Error: pp_od_clk_voltage not writable or not found" >> "$LOG_FILE"
        return 1
    fi
    max_index=$(grep -i '^sclk' "$PP_OD_FILE" | awk '{print $2}' | tail -n1)
    echo "s 0 $freq" | sudo tee "$PP_OD_FILE" >> "$LOG_FILE"
    echo "s $max_index $freq" | sudo tee "$PP_OD_FILE" >> "$LOG_FILE"
    echo "c" | sudo tee "$PP_OD_FILE" >> "$LOG_FILE"
    return 0
}

case "$GPU_TYPE" in
    amd)
        if [[ "$GPU_MAX_FREQ" -le "$ORIGINAL_GPU_MAX_FREQ" ]]; then
            set_amd_freq "$GPU_MAX_FREQ"
        else
            echo "GPUControl Error: AMD freq $GPU_MAX_FREQ MHz exceeds original max $ORIGINAL_GPU_MAX_FREQ MHz" >> "$LOG_FILE"
        fi
        ;;
    intel|mali|adreno)
        if [[ "$GPU_MAX_FREQ" -le "$ORIGINAL_GPU_MAX_FREQ" ]]; then
            echo "$GPU_MAX_FREQ" | sudo tee "$GPU_FREQ_PATH" >> "$LOG_FILE" 2>&1
        else
            echo "GPUControl Error: $GPU_TYPE freq $GPU_MAX_FREQ exceeds original max $ORIGINAL_GPU_MAX_FREQ" >> "$LOG_FILE"
        fi
        ;;
    *)
        echo "GPUControl Error: Unsupported GPU type '$GPU_TYPE'" >> "$LOG_FILE"
        ;;
esac
