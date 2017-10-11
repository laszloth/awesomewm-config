#!/bin/sh

if ! pidof spotify >/dev/null 2>&1; then
    spotify &
else
    $(dirname $(realpath $0))/spotify_dbus.sh c PlayPause
fi
exit 0
