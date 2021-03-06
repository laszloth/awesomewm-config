#!/bin/sh

TPADID=$(xinput list | grep -i 'touchpad' | grep -o 'id=[0-9]\+' | cut -d '=' -f2)
TPADSTATUS=$(xinput list-props $TPADID | grep 'Device Enabled' | sed -e 's/.*\:[ \t]\+//g')

if [ $TPADSTATUS -eq 0 ]; then
  xinput -enable $TPADID
else
  xinput -disable $TPADID
fi

exit 0

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=sh
