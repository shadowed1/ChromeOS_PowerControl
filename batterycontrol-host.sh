#!/bin/bash

read_json() {
    read -r -n4 lenbytes
    len=$(printf "%d" "'$lenbytes")
    read -r -n"$len" msg
    echo "$msg"
}

write_json() {
    resp="$1"
    len=${#resp}
    printf "$(printf '\\x%02x' $((len & 0xFF)) $(( (len >> 8) & 0xFF)) $(( (len >> 16) & 0xFF)) $(( (len >> 24) & 0xFF)))$resp"
}

while true; do
    msg=$(read_json)
    cmd=$(echo "$msg" | jq -r '.command')
    arg=$(echo "$msg" | jq -r '.arg // empty')

    case "$cmd" in
        status)
            output=$(/usr/local/bin/batterycontrol status)
            ;;
        start)
            output=$(/usr/local/bin/batterycontrol start)
            ;;
        stop)
            output=$(/usr/local/bin/batterycontrol stop)
            ;;
        set)
            output=$(/usr/local/bin/batterycontrol "$arg")
            ;;
        *)
            output="Unknown command: $cmd"
            ;;
    esac

    response=$(jq -n --arg out "$output" '{status:"ok", output:$out}')
    write_json "$response"
done
