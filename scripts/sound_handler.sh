#!/bin/sh

get_info() {
    DEF_SINK=$(pactl info | awk -F": " '/^Default Sink: /{print $2}')
    if [ -z "$DEF_SINK" ]; then
        >&2 echo "pactl error"
        exit 1
    fi
    DEF_SINK_INDEX=$(pactl list sinks short | grep "$DEF_SINK" | awk '{print $1}')
    SINK_DATA=$(pactl list sinks | awk "/Sink #$DEF_SINK_INDEX/,/Ports:/" | sed 's/^\s*//g')
    MUTED=$(echo "$SINK_DATA" | grep -c "Mute: no")
    VOLUME=$(echo "$SINK_DATA" | grep "^Volume" | awk '{print $5}' | tr -d '%')
    BUS=$(echo "$SINK_DATA" | sed -n 's#device.bus = "\(.*\)"#\1#p')
    JACK=$(cat /proc/asound/card1/codec#0 | grep "Pin-ctls:" | head -3 | tail -1 | grep -c OUT)
}

print_info() {
    echo "DEF_SINK=$DEF_SINK"
    echo "DEF_SINK_INDEX=$DEF_SINK_INDEX"
    echo -n "MUTED="
        if [ $MUTED -eq 0 ]; then
            echo "true"
        else
            echo "false"
        fi
    echo "VOLUME=$VOLUME%"
    echo "BUS=$BUS"
    echo -n "JACK="
        if [ $JACK -eq 0 ]; then
            echo "plugged"
        else
            echo "unplugged"
        fi
}

# $1: - or +
# $2: base step
# $3: usb step
vol_handler() {
    STEP=$2
    # set step according to bus type
    if [ "$BUS" = "usb" ]; then
        STEP=$3
    fi

    # pactl stops at 0
    NEWVOL=$((VOLUME${1}STEP))
    if [ $NEWVOL -lt 0 ]; then
        NEWVOL=0
    fi

    pactl set-sink-volume $DEF_SINK_INDEX ${1}${STEP}%

    # "send" results
    echo -n $DEF_SINK_INDEX $((1-MUTED)) $NEWVOL $BUS $((1-JACK))
}

case $1 in
    # used by awesome
    raw)
        get_info
        echo -n $DEF_SINK_INDEX $((1-MUTED)) $VOLUME $BUS $((1-JACK))
    ;;
    setvol)
        get_info
        vol_handler $2 $3 $4
    ;;
    info)
        get_info
        print_info
    ;;
    index)
        get_info
        echo $DEF_SINK_INDEX
    ;;
    name)
        get_info
        echo $DEF_SINK
    ;;
    muted)
        get_info
        if [ $MUTED -eq 0 ]; then
            echo "true"
        else
            echo "false"
        fi
    ;;
    vol)
        get_info
        echo "$VOLUME%"
    ;;
    bus)
        get_info
        echo $BUS
    ;;
    jack)
        get_info
        if [ $JACK -eq 0 ]; then
            echo "plugged"
        else
            echo "unplugged"
        fi
    ;;
    *)
        echo "Usage: $(basename $0) {raw|setvol|info|index|name|muted|vol|bus|jack}"
        exit 1
    ;;
esac

exit 0
