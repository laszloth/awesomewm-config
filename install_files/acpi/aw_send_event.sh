#!/bin/sh

AW_PID=$(pgrep awesome | head -1)
if [ $? -eq 0 ]; then
  AW_UID=$(cat /proc/$AW_PID/status | grep "^Uid:" | awk '{print $2}')
  AW_USER=$(getent passwd $AW_UID | cut -d':' -f1)
  CMD="export DISPLAY=:0; export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$AW_UID/bus; echo 'ext_event_handler(\"$1\")' | awesome-client"
  runuser -l $AW_USER -c "$CMD"
fi

exit 0

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=sh
