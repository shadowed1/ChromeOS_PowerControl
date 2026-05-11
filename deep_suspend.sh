#!/bin/bash
. "/usr/share/misc/shflags"
LOG_FILE="/var/log/sleepcontrol.log"
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

BATTERY_PATH=""
STATUS_PATH=""
consecutive_deep_suspends=0
last_capacity_before_suspend=-1

for f in suspend_duration backup_rtc pre_suspend_command post_resume_command; do
    FLAGS_DEFINED=("${FLAGS_DEFINED[@]/$f/}")
    unset "FLAGS_$f" 2>/dev/null || true
done

DEFINE_integer suspend_duration 720 "seconds" 2>/dev/null
DEFINE_boolean backup_rtc "${FLAGS_FALSE}" "rtc for backup" 2>/dev/null
DEFINE_string pre_suspend_command "" "eval before suspend" 2>/dev/null
DEFINE_string post_resume_command "" "eval after resume" 2>/dev/null

FLAGS "$@" || exit 1

FLAGS_suspend_duration=${FLAGS_suspend_duration:-720}
FLAGS_backup_rtc=${FLAGS_backup_rtc:-${FLAGS_FALSE}}
FLAGS_pre_suspend_command=${FLAGS_pre_suspend_command:-""}
FLAGS_post_resume_command=${FLAGS_post_resume_command:-""}

if [ "${FLAGS_backup_rtc}" -eq "${FLAGS_TRUE}" ] &&
   [ ! -e /sys/class/rtc/rtc1/wakealarm ]; then
  FLAGS_backup_rtc=${FLAGS_FALSE}
fi

detect_battery() {
    BATTERY_PATH=""
    STATUS_PATH=""

    for d in /sys/class/power_supply/*; do
        [[ -f "$d/capacity" ]] || continue
        [[ -f "$d/status" ]] || continue
        [[ -f "$d/voltage_min_design" ]] || continue

        if [[ -f "$d/type" ]]; then
            read -r type < "$d/type"
            [[ "$type" == "Battery" ]] || continue
        fi

        case "$d" in
            *hid*|*HID*|*stylus*|*pen*) continue ;;
        esac

        read -r status < "$d/status"
        [[ "$status" != "Unknown" ]] || continue

        BATTERY_PATH="$d/capacity"
        STATUS_PATH="$d/status"
        return 0
    done

    echo "${RED}No internal battery detected!${RESET}" | tee -a "$LOG_FILE"
    return 1
}

get_battery_capacity() {
    if [[ -n "$BATTERY_PATH" && -f "$BATTERY_PATH" ]]; then
        read -r capacity < "$BATTERY_PATH"
        echo "$capacity"
    else
        echo ""
    fi
}

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
detect_battery

while true; do
  sync

  echo 0 | sudo tee /sys/class/rtc/rtc0/wakealarm > /dev/null
  echo "+${FLAGS_suspend_duration}" | sudo tee /sys/class/rtc/rtc0/wakealarm > /dev/null

  if [ "${FLAGS_backup_rtc}" -eq "${FLAGS_TRUE}" ]; then
    echo 0 | sudo tee /sys/class/rtc/rtc1/wakealarm > /dev/null
    echo "+$(( FLAGS_suspend_duration + 5 ))" | sudo tee /sys/class/rtc/rtc1/wakealarm > /dev/null
  fi

  if [ -n "${FLAGS_pre_suspend_command}" ]; then
    eval "${FLAGS_pre_suspend_command}"
  fi

  if [[ -n "$BATTERY_PATH" && -f "$BATTERY_PATH" ]]; then
      read -r last_capacity_before_suspend < "$BATTERY_PATH"
  fi

  start_time="$(cat /sys/class/rtc/rtc0/since_epoch)"
  sudo stop tlsdated >/dev/null 2>&1
  cras_test_client --suspend 30 >/dev/null 2>&1
  sleep 0.1
  echo mem | sudo tee /sys/power/state >/dev/null 2>&1
  end_time="$(cat /sys/class/rtc/rtc0/since_epoch)"
  actual_sleep_time=$(( end_time - start_time ))

  echo "${BLUE}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Slept for ${RESET}${YELLOW}${actual_sleep_time} / ${FLAGS_suspend_duration} seconds${RESET}" >> "$LOG_FILE"

  if [ -n "${FLAGS_post_resume_command}" ]; then
    eval "${FLAGS_post_resume_command}"
  fi

  sudo start tlsdated >/dev/null 2>&1

  current_capacity=""
  current_status=""
  if [[ -n "$STATUS_PATH" && -f "$STATUS_PATH" ]]; then
      read -r current_status < "$STATUS_PATH"
  fi
  if [[ -n "$BATTERY_PATH" && -f "$BATTERY_PATH" ]]; then
      read -r current_capacity < "$BATTERY_PATH"
  fi

  lower_bound=$(( FLAGS_suspend_duration - 5 ))
  upper_bound=$(( FLAGS_suspend_duration + 5 ))
  
  if [ "${actual_sleep_time}" -lt "${lower_bound}" ] || [ "${actual_sleep_time}" -gt "${upper_bound}" ]; then
      echo "${BLUE}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Early wakeup detected, resetting consecutive suspend counter${RESET}" >> "$LOG_FILE"
      consecutive_deep_suspends=0
      echo "${BLUE}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Ending Suspend Loop${RESET}" >> "$LOG_FILE"
      cras_test_client --suspend 0 >/dev/null 2>&1
      sleep 0.4
      break
  fi

  consecutive_deep_suspends=$(( consecutive_deep_suspends + 1 ))
  echo "${BLUE}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Consecutive deep suspends: ${consecutive_deep_suspends}${RESET}" >> "$LOG_FILE"

  if [ "${consecutive_deep_suspends}" -ge 3 ]; then
      if [[ -n "$current_capacity" && "$current_capacity" -le 3 ]]; then
          if [ "$current_status" == "Discharging" ]; then
              echo "${RED}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Battery Discharging (Critical ${current_capacity}%), initiating shutdown${RESET}" >> "$LOG_FILE"
              sudo shutdown -h now >> "$LOG_FILE" 2>&1
              exit 0
          elif [ "$current_status" == "Charging" ]; then
              if [[ "$last_capacity_before_suspend" -ge 0 ]]; then
                  capacity_change=$(( last_capacity_before_suspend - current_capacity ))
                  if [ "$capacity_change" -lt 1 ]; then
                      echo "${YELLOW}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Charging detected: ${capacity_change}% difference. ${RESET}" >> "$LOG_FILE"
                      consecutive_deep_suspends=0
                  else
                      echo "${RED}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Charging but capacity dropped by ${capacity_change}%. Initiating shutdown${RESET}" >> "$LOG_FILE"
                      sudo shutdown -h now >> "$LOG_FILE" 2>&1
                      exit 0
                  fi
              else
                  echo "${YELLOW}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Charging detected. ${RESET}" >> "$LOG_FILE"
                  consecutive_deep_suspends=0
              fi
          else
              echo "${YELLOW}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Battery status unknown. ${RESET}" >> "$LOG_FILE"
              consecutive_deep_suspends=0
          fi
      fi
  fi

  sleep 15
  echo "${BLUE}$(printf '%(%Y-%m-%d %H:%M:%S)T\n' -1) - Restarting Sleep Loop${RESET}" >> "$LOG_FILE"
done
