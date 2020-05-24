#!/bin/bash

err_count=0

test_cmd() {
  local -r cmd=$1
  if ! command -v $cmd; then
    echo "debug_print_perm(\"command not found: '$cmd'\")" | awesome-client
    err_count=$((err_count+1))
  fi
}

test_cmd_running() {
  local -r cmd=$1
  if ! pgrep -f $cmd; then
    echo "debug_print_perm(\"tool not running: '$cmd'\")" | awesome-client
    err_count=$((err_count+1))
  fi
}

# test tools needed to function properly
test_cmd bc
test_cmd gnome-calculator
test_cmd konsole
test_cmd laptop-detect
test_cmd laptop-detect
test_cmd physlock
test_cmd pulseaudio
test_cmd vim
test_cmd xbacklight

# test running tools needed to function properly
test_cmd_running xcompmgr

exit $err_count

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=sh
