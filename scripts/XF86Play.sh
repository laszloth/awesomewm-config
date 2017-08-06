#!/bin/bash

SPOTPID=$(pidof spotify)

if [ $? -eq 1 ]; then
    spotify --minimized %U
else
    dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause
fi
