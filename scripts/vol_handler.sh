#!/bin/bash

# $1: - or +
# $2: base step
# $3: usb step

SCRIPTDIR=$(dirname $(realpath $0))

read -ra RAWDATA <<< "$($SCRIPTDIR/sound_handler.sh raw)"
STEP=$2
# set step according to bus type
if [ "${RAWDATA[3]}" = "usb" ]; then
    STEP=$3
fi
VOLUME=${RAWDATA[2]}

# pactl stops at 0
temp=$((VOLUME${1}STEP))
if [ $temp -gt 0 ]; then
    RAWDATA[2]=$temp
else
    RAWDATA[2]=0
fi

pactl set-sink-volume ${RAWDATA[0]} ${1}${STEP}%

# "send" results
echo "${RAWDATA[@]}"

exit 0
