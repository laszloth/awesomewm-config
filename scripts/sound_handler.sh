#!/bin/bash

readonly lockfile="/tmp/aw_sound_handler.lock"
exec 200>$lockfile
flock --wait $(bc <<< "scale=1;1/10") -E 9 200 || exit $?
echo $$ 1>&200

print_usage() {
local -r usage=" \

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
echo "$usage"
}

log_err() {
  echo >&2 "sound_handler:" "$1"
}

get_info() {
  def_sink=$(pactl info | sed -n 's#^Default Sink: \(.*\)#\1#p')
  [[ -z "$def_sink" ]] && log_err "PulseAudio error" && exit 2
  def_sink_index=$(pactl list sinks short | grep "$def_sink" | awk '{print $1}')
  sink_data=$(pactl list sinks | awk "/Sink #$def_sink_index/,/Ports:/" | sed 's/^\s*//g')
  muted=$(echo "$sink_data" | grep -c "^Mute: no")
  volume=$(echo "$sink_data" | grep "^Volume:" | awk '{print $5}' | tr -d '%')
  bus=$(echo "$sink_data" | sed -n 's#device.bus = "\(.*\)"#\1#p')
  sample_spec=$(echo "$sink_data" | sed -n 's#^Sample Specification: \(.*\)$#\1#p')
  bit_depth=$(echo "$sample_spec" | cut -d' ' -f1)
  channels=$(echo "$sample_spec" | cut -d' ' -f2 | tr -d 'ch')
  sample_rate=$(echo "$sample_spec" | cut -d' ' -f3 | tr -d 'Hz')
  has_vol_ctrl=$(echo "$sink_data" | grep "^Flags:" | grep -c HW_VOLUME_CTRL)
  jack=$(cat /proc/asound/card?/codec#0 | grep "Pin-ctls:" | head -3 | tail -1 | grep -c OUT)
}

print_info() {
  echo "def_sink_index = $def_sink_index"
  echo "def_sink = $def_sink"
  echo -n "muted = "
  [[ $muted -eq 0 ]] && echo "true" || echo "false"
  echo "volume = $volume%"
  echo "bus = $bus"
  echo -n "jack = "
  [[ $jack -eq 0 ]] && echo "plugged" || echo "unplugged"
  echo "sample_spec = $sample_spec"
  echo -n "has_vol_ctrl = "
  [[ $has_vol_ctrl -eq 1 ]] && echo "true" || echo "false"
}

print_raw_info() {
  echo "${def_sink_index};${def_sink};${volume};$((1-muted));$((1-jack));${bus};${bit_depth};${channels};${sample_rate};${has_vol_ctrl}"
}

# $1: sink name or index, can be emitted
# $2: new volume or new relative volume w/ operand
# $show_result: call print_raw_info w/ updated volume
set_volume() {
  local vol
  local sink

  [[ -z "$1" ]] && log_err "please provide absolute/relative volume setting" && exit 1
  if [[ -z "$2" ]]; then
    vol=$1
    get_info
    sink=$def_sink
  else
    sink=$1
    vol=$2
  fi
  vol=${vol//%}

  pactl set-sink-volume $sink $vol%

  if [[ -n "$show_result" ]]; then
    op=$(expr "$vol" : '\([+-]*\)')
    [[ -z "$op" ]] && volume=$vol || volume=$((volume${vol}))
    [[ $volume -lt 0 ]] && volume=0
    print_raw_info
  fi
}

toggle_mute() {
  if [[ -z "$1" ]]; then
    get_info
    sink=$def_sink
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
    show_result=1
    shift
    set_volume $@
    ;;
  -t|--toggle-mute)
    shift
    toggle_mute $@
    ;;
  -I|--index)
    get_info
    echo "$def_sink_index"
    ;;
  -n|--name)
    get_info
    echo "$def_sink"
    ;;
  -m|--muted)
    get_info
    [[ $muted -eq 0 ]] && echo "true" || echo "false"
    ;;
  -v|--volume)
    get_info
    echo "$volume%"
    ;;
  -b|--bus)
    get_info
    echo "$bus"
    ;;
  -j|--jack)
    get_info
    [[ $jack -eq 0 ]] && echo "plugged" || echo "unplugged"
    ;;
  -d|--sample-spec)
    get_info
    echo "$sample_spec"
    ;;
  -V|--volume-control)
    get_info
    [[ $has_vol_ctrl -eq 1 ]] && echo "true" || echo "false"
    ;;
  -h|--help)
    print_usage
    ;;
  *)
    print_usage >&2
    exit 1
    ;;
esac

exit 0

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=sh
