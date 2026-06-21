#!/bin/bash
# Toggle On/Off ArcVM

RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

CMD="${1:-status}"

ARC_PIDS() {
    pgrep -f "crosvm.*ARCVM"
}

case "$CMD" in
    stop)
        pids=$(ARC_PIDS)
        if [ -z "$pids" ]; then
            echo "${RED}ARCVM Stopped${RESET}"
            exit 0
        fi

        for pid in $pids; do
            state=$(awk '{print $3}' /proc/$pid/stat 2>/dev/null)
            if [ "$state" != "T" ]; then
                sudo kill -STOP "$pid"
            else
                echo "${RESET}${RED}ARCVM PID $pid: FROZEN${RESET}"
            fi
        done
        ;;
    start)
        pids=$(ARC_PIDS)
        if [ -z "$pids" ]; then
            echo "${GREEN}ARCVM Starting${RESET}"
            exit 0
        fi

        for pid in $pids; do
            sudo kill -CONT "$pid"
        done
        ;;
    status)
        pids=$(ARC_PIDS)
        if [ -z "$pids" ]; then
            echo "${RED}ARCVM Stopped${RESET}"
            exit 0
        fi

        for pid in $pids; do
            state=$(awk '{print $3}' /proc/$pid/stat)
            case "$state" in
                T) echo "${RED}ARCVM PID $pid: FROZEN${RESET}" ;;
                *) echo "${GREEN}ARCVM PID $pid: RUNNING - ($state) ${RESET}" ;;
            esac
        done
        ;;

    *)
        exit 1
        ;;
esac
