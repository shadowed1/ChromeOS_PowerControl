#!/bin/sh
. "/usr/share/misc/shflags"
DEFINE_integer suspend_duration 3600 "Duration to sleep in seconds (default: 1 hour)" d
DEFINE_boolean force_deep_sleep "${FLAGS_TRUE}" "S3 deep sleep vs 2idle"
DEFINE_boolean backup_rtc "${FLAGS_FALSE}" "rtc for backup"
DEFINE_string pre_suspend_command "" "eval before suspend"
DEFINE_string post_resume_command "" "eval after resume"
FLAGS "$@" || exit 1

if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root." 1>&2
  exit 1
fi

if [ "${FLAGS_backup_rtc}" -eq "${FLAGS_TRUE}" ] &&
   [ ! -e /sys/class/rtc/rtc1/wakealarm ]; then
  echo "rtc1 not present. No wakealarm"
  FLAGS_backup_rtc=${FLAGS_FALSE}
fi

check_sleep_mode() {
  if [ -e /sys/power/mem_sleep ]; then
    cat /sys/power/mem_sleep
  else
    echo "Cannot determine sleep mode"
  fi
}

set_deep_sleep() {
  if [ -e /sys/power/mem_sleep ]; then
    if grep -q '\[deep\]' /sys/power/mem_sleep; then
      echo "Deep sleep already enabled"
      return 0
    elif grep -q 'deep' /sys/power/mem_sleep; then
      echo "Enabling deep sleep (S3)..."
      echo deep > /sys/power/mem_sleep
      if grep -q '\[deep\]' /sys/power/mem_sleep; then
        echo "Successfully enabled deep sleep"
        return 0
      else
        echo "Failed to enable deep sleep"
        return 1
      fi
    else
      echo "Deep sleep not available! "
      echo "Available modes: $(cat /sys/power/mem_sleep)"
      return 1
    fi
  else
    echo "/sys/power/mem_sleep not found."
    return 1
  fi
}

echo "Current sleep mode: $(check_sleep_mode)"

if [ "${FLAGS_force_deep_sleep}" -eq "${FLAGS_TRUE}" ]; then
  if ! set_deep_sleep; then
    echo "Cannot enable deep sleep. Exiting."
    exit 1
  fi
fi

echo "Sleep duration: ${FLAGS_suspend_duration} seconds"
echo "Backup RTC: $([ "${FLAGS_backup_rtc}" -eq "${FLAGS_TRUE}" ] && echo "enabled" || echo "disabled")"

sync

echo "Setting wake alarm for ${FLAGS_suspend_duration} seconds from now..."
echo 0 > /sys/class/rtc/rtc0/wakealarm
echo "+${FLAGS_suspend_duration}" > /sys/class/rtc/rtc0/wakealarm

if [ "${FLAGS_backup_rtc}" -eq "${FLAGS_TRUE}" ]; then
  echo "Setting backup RTC alarm..."
  echo 0 > /sys/class/rtc/rtc1/wakealarm
  echo "+$(( FLAGS_suspend_duration + 5 ))" > /sys/class/rtc/rtc1/wakealarm
fi

if [ -n "${FLAGS_pre_suspend_command}" ]; then
  echo "Running pre-suspend command: ${FLAGS_pre_suspend_command}"
  eval "${FLAGS_pre_suspend_command}"
fi

start_time="$(cat /sys/class/rtc/rtc0/since_epoch)"
stop tlsdated 2>/dev/null
echo mem > /sys/power/state
end_time="$(cat /sys/class/rtc/rtc0/since_epoch)"
actual_sleep_time=$(( end_time - start_time ))

echo "Slept for ${actual_sleep_time} seconds (expected ${FLAGS_suspend_duration})"

if [ -n "${FLAGS_post_resume_command}" ]; then
  echo "Running post-resume command: ${FLAGS_post_resume_command}"
  eval "${FLAGS_post_resume_command}"
fi

start tlsdated 2>/dev/null

exit 0
