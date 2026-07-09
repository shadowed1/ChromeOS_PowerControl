#!/bin/bash
# deep_suspend_battery.sh
. "/usr/share/misc/shflags"
LOG_FILE="/var/log/sleepcontrol.log"
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

set_sleep_mode() {
  if [ ! -e /sys/power/mem_sleep ]; then
    echo "/sys/power/mem_sleep not found."
    return 1
  fi

  if grep -q '\[deep\]' /sys/power/mem_sleep || grep -q 'deep' /sys/power/mem_sleep; then
    echo deep | sudo tee /sys/power/mem_sleep > /dev/null
    if grep -q '\[deep\]' /sys/power/mem_sleep || grep -q 'deep' /sys/power/mem_sleep; then
      return 0
    fi
  fi

  if grep -q '\[s2idle\]' /sys/power/mem_sleep || grep -q 's2idle' /sys/power/mem_sleep; then
    echo s2idle | sudo tee /sys/power/mem_sleep > /dev/null
    return 0
  fi

  return 1
}

set_sleep_mode

sync
sudo stop tlsdated >/dev/null 2>&1
cras_test_client --suspend 30 >/dev/null 2>&1
sleep 0.1

start_time="$(cat /sys/class/rtc/rtc0/since_epoch 2>/dev/null)"
echo mem | sudo tee /sys/power/state >/dev/null 2>&1
end_time="$(cat /sys/class/rtc/rtc0/since_epoch 2>/dev/null)"

if [[ -n "$start_time" && -n "$end_time" ]]; then
    actual_sleep_time=$(( end_time - start_time ))
    echo "${BLUE}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Battery suspend: slept ${RESET}${YELLOW}${actual_sleep_time}s${RESET}" >> "$LOG_FILE"
fi

sudo start tlsdated >/dev/null 2>&1
cras_test_client --suspend 0 >/dev/null 2>&1
