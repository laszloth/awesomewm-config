#!/bin/bash

CMD_NOTF=0

function run {
  if ! command -v $1 ;then
    CMD_NOTF=$((CMD_NOTF+1))
    return
  fi

  if ! pgrep $1 ;then
    $@&
  fi
}

# run 'em
run xcompmgr
#run conky -q -c ~/.config/awesome/conky.cfg
run parcellite

exit $CMD_NOTF
