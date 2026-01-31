#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
BOLD=$(tput bold)
RESET=$(tput sgr0)

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
                echo "${RESET}${CYAN}ARCVM pid $pid already frozen${RESET}"
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
                T) echo "${CYAN}ARCVM pid $pid: FROZEN${RESET}" ;;
                *) echo "${GREEN}ARCVM pid $pid: RUNNING ($state)${RESET}" ;;
            esac
        done
        ;;

    *)
        echo "${CYAN}Usage: arc [start|stop|status]${RESET}"
        exit 1
        ;;
esac
