#!/bin/bash

#set -x

LOCKFILE="/tmp/aw_sound_handler.lock"
exec 200>$LOCKFILE
flock --wait $(bc <<< "scale=1;1/10") -E 9 200 || exit $?
echo $$ 1>&200

USAGE="\

Usage: $(basename $0) [option] [arg]
  Options:
    -i, --info: print every info collected
    -r, --raw: print info in raw, short format
    -s, --set-volume: set volume on sink or on default
    -S, --set-get-volume: same as -s, but print new values
    -t, --toggle-mute: toggle mute on sink or on default

    -I, --index: print index of default sink
    -n, --name: print name of default sink
    -m, --muted: print mute info (bool)
    -v, --volume: print volume info
    -b, --bus: print bus info
    -j, --jack: print jack plug info (bool)
    -d, --sample-spec: print sample specification
    -V, --volume-control: print volume control info (bool)
    -h, --help: print this help

  Exit error values:
    1: missing/incorrect option or argument(s)
    2: error in pactl/pacmd
    9: flock couldn't acquire lock
"

function log_err {
  echo >&2 "sound_handler:" "$1"
}

function get_info {
  DEF_SINK=$(pactl info | sed -n 's#^Default Sink: \(.*\)#\1#p')
  [ -z "$DEF_SINK" ] && log_err "PulseAudio error" && exit 2
  DEF_SINK_INDEX=$(pactl list sinks short | grep "$DEF_SINK" | awk '{print $1}')
  SINK_DATA=$(pactl list sinks | awk "/Sink #$DEF_SINK_INDEX/,/Ports:/" | sed 's/^\s*//g')
  MUTED=$(echo "$SINK_DATA" | grep -c "^Mute: no")
  VOLUME=$(echo "$SINK_DATA" | grep "^Volume:" | awk '{print $5}' | tr -d '%')
  BUS=$(echo "$SINK_DATA" | sed -n 's#device.bus = "\(.*\)"#\1#p')
  SAMPLE_SPEC=$(echo "$SINK_DATA" | sed -n 's#^Sample Specification: \(.*\)$#\1#p')
  BIT_DEPTH=$(echo "$SAMPLE_SPEC" | cut -d' ' -f1)
  CHANNELS=$(echo "$SAMPLE_SPEC" | cut -d' ' -f2 | tr -d 'ch')
  SAMPLE_RATE=$(echo "$SAMPLE_SPEC" | cut -d' ' -f3 | tr -d 'Hz')
  SYSFS=$(echo "$SINK_DATA" | sed -n 's#sysfs.path = "\(.*\)"#/sys\1#p')
  HAS_VOL_CTRL=$(echo "$SINK_DATA" | grep "^Flags:" | grep -c HW_VOLUME_CTRL)
  JACK=$(cat /proc/asound/card?/codec#0 | grep "Pin-ctls:" | head -3 | tail -1 | grep -c OUT)
}

function print_info {
  echo "DEF_SINK_INDEX = $DEF_SINK_INDEX"
  echo "DEF_SINK = $DEF_SINK"
  echo -n "MUTED = "
  [ $MUTED -eq 0 ] && echo "true" || echo "false"
  echo "VOLUME = $VOLUME%"
  echo "BUS = $BUS"
  echo -n "JACK = "
  [ $JACK -eq 0 ] && echo "plugged" || echo "unplugged"
  echo "SAMPLE_SPEC = $SAMPLE_SPEC"
  echo -n "HAS_VOL_CTRL = "
  [ $HAS_VOL_CTRL -eq 1 ] && echo "true" || echo "false"
  echo "SYSFS = $SYSFS"
}

function print_raw_info {
  echo "${DEF_SINK_INDEX};${DEF_SINK};${VOLUME};$((1-MUTED));$((1-JACK));${BUS};${BIT_DEPTH};${CHANNELS};${SAMPLE_RATE};${HAS_VOL_CTRL}"
}

# $1: sink name or index, can be emitted
# $2: new volume or new relative volume w/ operand
# $SHOW_RESULT: call print_raw_info w/ updated volume
function set_volume {
  [ -z "$1" ] && log_err "please provide absolute/relative volume setting" && exit 1
  if [ -z "$2" ]; then
    volume=$1
    get_info
    sink=$DEF_SINK
  else
    sink=$1
    volume=$2
  fi
  volume=${volume//%}
  pactl set-sink-volume $sink $volume%

  if [ -n "$SHOW_RESULT" ]; then
    op=$(expr "$volume" : '\([+-]*\)')
    [ -z "$op" ] && VOLUME=$volume || VOLUME=$((VOLUME${volume}))
    [ $VOLUME -lt 0 ] && VOLUME=0
    print_raw_info
  fi
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
    print_raw_info
  ;;
  -s|--set-volume)
    shift
    set_volume $@
  ;;
  -S|--set-get-volume)
    SHOW_RESULT=1
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
  -d|--sample-spec)
    get_info
    echo "$SAMPLE_SPEC"
  ;;
  -V|--volume-control)
    get_info
    [ $HAS_VOL_CTRL -eq 1 ] && echo "true" || echo "false"
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

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=sh
