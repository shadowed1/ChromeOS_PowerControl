if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="/usr/local/bin/ChromeOS_PowerControl"
fi
export STARTUP_BATTERYCONTROL
export STARTUP_FANCONTROL
export STARTUP_POWERCONTROL
export STARTUP_GPUCONTROL
export STARTUP_SLEEPCONTROL
