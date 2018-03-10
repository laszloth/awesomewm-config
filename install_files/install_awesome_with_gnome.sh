#!/bin/sh

cp -nv ./55awesome-javaworkaround /etc/X11/Xsession.d/

cp -v ./awesome.desktop /usr/share/applications/
cp -v ./awesome-xsessions.desktop /usr/share/xsessions/awesome.desktop
cp -v ./awesome.session /usr/share/gnome-session/sessions/
cp -v ./10-awesome.conf /etc/lightdm/lightdm.conf.d/

cp -rv ./acpi/ /etc/

echo "done"
