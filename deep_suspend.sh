#!/bin/bash
. "/usr/share/misc/shflags"

for f in suspend_duration backup_rtc pre_suspend_command post_resume_command; do
    FLAGS_DEFINED=("${FLAGS_DEFINED[@]/$f/}")
    unset "FLAGS_$f" 2>/dev/null || true
done

DEFINE_integer suspend_duration 300 "seconds" 2>/dev/null
DEFINE_boolean backup_rtc "${FLAGS_FALSE}" "rtc for backup" 2>/dev/null
DEFINE_string pre_suspend_command "" "eval before suspend" 2>/dev/null
DEFINE_string post_resume_command "" "eval after resume" 2>/dev/null

FLAGS "$@" || exit 1

FLAGS_suspend_duration=${FLAGS_suspend_duration:-300}
FLAGS_backup_rtc=${FLAGS_backup_rtc:-${FLAGS_FALSE}}
FLAGS_pre_suspend_command=${FLAGS_pre_suspend_command:-""}
FLAGS_post_resume_command=${FLAGS_post_resume_command:-""}

if [ "${FLAGS_backup_rtc}" -eq "${FLAGS_TRUE}" ] &&
   [ ! -e /sys/class/rtc/rtc1/wakealarm ]; then
  FLAGS_backup_rtc=${FLAGS_FALSE}
fi

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

echo "${BLUE}Sleep duration: ${FLAGS_suspend_duration} seconds ${RESET}"

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

  start_time="$(cat /sys/class/rtc/rtc0/since_epoch)"
  sudo stop tlsdated >/dev/null 2>&1
  echo mem | sudo tee /sys/power/state >/dev/null 2>&1
  end_time="$(cat /sys/class/rtc/rtc0/since_epoch)"
  actual_sleep_time=$(( end_time - start_time ))

  echo "${MAGENTA}Slept for ${BOLD}${actual_sleep_time} seconds${RESET}${MAGENTA} (expected ${FLAGS_suspend_duration})"

  if [ -n "${FLAGS_post_resume_command}" ]; then
    eval "${FLAGS_post_resume_command}"
  fi

  sudo start tlsdated >/dev/null 2>&1

  lower_bound=$(( FLAGS_suspend_duration - 5 ))
  upper_bound=$(( FLAGS_suspend_duration + 5 ))
  if [ "${actual_sleep_time}" -lt "${lower_bound}" ] || [ "${actual_sleep_time}" -gt "${upper_bound}" ]; then
    echo "${BLUE}Sleep time ${BOLD}${actual_sleep_time}s${RESET} out of range (${lower_bound}-${upper_bound}s). ${RESET}"
    break
  fi
  sleep 15
done
