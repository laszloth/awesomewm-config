#!/bin/bash

readonly SCRIPTS_DIR=$(dirname $(realpath ${0}))
readonly AW_CFG_ROOT=$(readlink -e ${SCRIPTS_DIR}/..)

readonly aw_ver_file=${AW_CFG_ROOT}/awesome.version

awesome --version > ${aw_ver_file}

git add ${aw_ver_file}
git commit -m "awesomewm to $(head -1 ${aw_ver_file} | awk '{print $2}')"

# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=sh
