#!/bin/sh

get_info() {
    DEF_SINK=$(pactl info | awk -F": " '/^Default Sink: /{print $2}')
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
    echo "MUTED=$MUTED"
    echo "VOLUME=$VOLUME"
    echo "BUS=$BUS"
    echo "JACK=$JACK"
}

case $1 in
    # used by awesome
    raw)
        get_info
        echo -n $DEF_SINK_INDEX $((1-MUTED)) $VOLUME $BUS $((1-JACK))
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
        echo $VOLUME
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
        echo "Usage: $(basename $0) {raw|info|index|name|muted|vol|bus|jack}"
        exit 1
    ;;
esac

exit 0
