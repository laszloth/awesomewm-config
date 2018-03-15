#!/bin/bash

LOCKFILE="/tmp/aw_sound_handler.lock"
exec 200>$LOCKFILE
flock --wait 1 200 || exit 1
echo $$ 1>&200

USAGE="\
Usage: $(basename $0) [option]
 Options:
  -i, --info: print every info collected
  -r, --raw: print info in raw, short format
  -s, --set-volume: set volume on sink or on default
  -t, --toggle-mute: toggle mute on sink or on default

  -I, --index: print index of default sink
  -n, --name: print name of default sink
  -m, --muted: print mute info
  -v, --volume: print volume info
  -b, --bus: print bus info
  -j, --jack: print jack plug info
  -h, --help: print this help
"

function get_info {
    DEF_SINK=$(pactl info | awk -F": " '/^Default Sink: /{print $2}')
    [ -z "$DEF_SINK" ] && echo "pactl error" >&2 && exit 1
    DEF_SINK_INDEX=$(pactl list sinks short | grep "$DEF_SINK" | awk '{print $1}')
    SINK_DATA=$(pactl list sinks | awk "/Sink #$DEF_SINK_INDEX/,/Ports:/" | sed 's/^\s*//g')
    MUTED=$(echo "$SINK_DATA" | grep -c "Mute: no")
    VOLUME=$(echo "$SINK_DATA" | grep "^Volume" | awk '{print $5}' | tr -d '%')
    BUS=$(echo "$SINK_DATA" | sed -n 's#device.bus = "\(.*\)"#\1#p')
    JACK=$(cat /proc/asound/card1/codec#0 | grep "Pin-ctls:" | head -3 | tail -1 | grep -c OUT)
}

function print_info {
    echo "DEF_SINK=$DEF_SINK"
    echo "DEF_SINK_INDEX=$DEF_SINK_INDEX"
    echo -n "MUTED="
    [ $MUTED -eq 0 ] && echo "true" || echo "false"
    echo "VOLUME=$VOLUME%"
    echo "BUS=$BUS"
    echo -n "JACK="
    [ $JACK -eq 0 ] && echo "plugged" || echo "unplugged"
}

function set_volume {
    [ -z "$1" ] && echo "no params given" >&2 && exit 1
    if [ -z "$2" ]; then
        volume=$1
        get_info
        sink=$DEF_SINK
    else
        sink=$1
        volume=$2
    fi
    pactl set-sink-volume $sink $volume%
}

function toggle_mute {
    if [ -z "$1" ]; then
        get_info
        sink=$DEF_SINK
    else
        sink=$1
    fi
    pactl set-sink-mute $sink toggle
}

case $1 in
    -i|--info)
        get_info
        print_info
    ;;
    -r|--raw)
        get_info
        echo -n $DEF_SINK $DEF_SINK_INDEX $VOLUME $((1-MUTED)) $((1-JACK)) $BUS
    ;;
    -s|--set-volume)
        shift
        set_volume $@
    ;;
    -t|--toggle-mute)
        shift
        toggle_mute $@
    ;;
    -I|--index)
        get_info
        echo "$DEF_SINK_INDEX"
    ;;
    -n|--name)
        get_info
        echo "$DEF_SINK"
    ;;
    -m|--muted)
        get_info
        [ $MUTED -eq 0 ] && echo "true" || echo "false"
    ;;
    -v|--volume)
        get_info
        echo "$VOLUME%"
    ;;
    -b|--bus)
        get_info
        echo "$BUS"
    ;;
    -j|--jack)
        get_info
        [ $JACK -eq 0 ] && echo "plugged" || echo "unplugged"
    ;;
    -h|--help)
        echo "$USAGE"
    ;;
    *)
        echo "$USAGE" >&2
        exit 1
    ;;
esac

exit 0
