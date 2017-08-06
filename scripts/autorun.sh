#!/bin/bash

function run {
  if ! pgrep $1 ;
  then
    $@&
  fi
}

# run 'em
run xcompmgr
#run conky -q -c ~/.config/awesome/conky.cfg
run parcellite
