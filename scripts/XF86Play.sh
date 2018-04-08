#!/bin/sh

if ! pidof spotify >/dev/null 2>&1; then
  spotify &
else
  $(dirname $(realpath $0))/spotify_dbus.sh c PlayPause
fi

exit 0

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=sh
