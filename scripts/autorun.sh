#!/bin/bash

CMD_NOTF=0

function run {
  if ! command -v $1 ;then
    CMD_NOTF=$((CMD_NOTF+1))
    echo "debug_print(\"command not found: '$1'\")" | awesome-client
    return
  fi

  if ! pgrep $1 ;then
    $@&
  fi
}

# run 'em
run xcompmgr
run light-locker
#run conky -q -c ~/.config/awesome/conky.cfg
run parcellite

exit $CMD_NOTF
