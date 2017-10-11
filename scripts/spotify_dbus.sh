#!/bin/sh

if ! pidof spotify >/dev/null 2>&1; then
    exit 1
fi

case $1 in
    c)
        dbus-send --print-reply --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.$2
    ;;
    q)
        qdbus org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.freedesktop.DBus.Properties.Get org.mpris.MediaPlayer2.Player $2
    ;;
    *)
        >&2 echo "usage $(basename $0) {c|q} <name>"
        exit 1
    ;;
esac
