#!/bin/sh

TPADID=`xinput list | grep -i "touchpad" | grep -o 'id=[0-9]\+' | cut -d '=' -f2`

TPADSTATUS=`xinput list-props ${TPADID} | grep Device\ Enabled | sed -e 's/.*\:[ \t]\+//g'`

if [ 0 -eq ${TPADSTATUS} ] ; then
    xinput -enable ${TPADID}
else
    xinput -disable ${TPADID}
fi
