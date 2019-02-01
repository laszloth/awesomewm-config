#!/bin/bash

readonly display_num=1
readonly resolution=1280x720
readonly script_dir=$(dirname $(realpath $0))
readonly config_path=$(readlink -f ${script_dir}/../awesomerc.lua)

Xephyr :"$display_num" -ac -br -noreset -screen "$resolution" &

sleep 1

DISPLAY=":${display_num}.0" awesome -c "$config_path"

exit 0
