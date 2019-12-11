#!/bin/bash

CMD_NOTF=0
SCRIPTDIR=$(dirname $(realpath $0))

function run {
  if ! command -v $1 ;then
    CMD_NOTF=$((CMD_NOTF+1))
    echo "debug_print_perm(\"command not found: '$1'\")" | awesome-client
    return
  fi

  if ! pgrep -f $1 ;then
    $@&
  fi
}

# test 'em
run laptop-detect

# run 'em
run xcompmgr
run conky -q -c ~/.config/awesome/conky.cfg

exit $CMD_NOTF

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=sh
