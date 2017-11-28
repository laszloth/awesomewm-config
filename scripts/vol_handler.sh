#!/bin/bash

# $1: - or +
# $2: base step
# $3: usb step

SCRIPTDIR=$(dirname $(realpath $0))

read -ra RAWDATA <<< "$($SCRIPTDIR/sound_handler.sh raw)"
STEP=$2
# bus type
if [ "${RAWDATA[3]}" = "usb" ]; then
    STEP=$3
fi

pactl set-sink-volume ${RAWDATA[0]} ${1}${STEP}%

RAWDATA[2]=$((${RAWDATA[2]}${1}${STEP}))
echo "${RAWDATA[@]}"

exit 0
