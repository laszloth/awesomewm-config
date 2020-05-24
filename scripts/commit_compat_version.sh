#!/bin/bash

readonly script_dir=$(dirname $(realpath ${0}))
readonly aw_cfg_root=$(readlink -e ${script_dir}/..)
readonly aw_ver_file=${aw_cfg_root}/awesome.version

awesome --version > ${aw_ver_file}

git add ${aw_ver_file}
git commit -m "awesomewm to $(head -1 ${aw_ver_file} | awk '{print $2}')"

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=sh
