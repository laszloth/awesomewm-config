#!/bin/sh

cp -v ./files/55awesome-javaworkaround /etc/X11/Xsession.d/
cp -v ./files/awesome.desktop /usr/share/applications/
cp -v ./files/awesome-xsessions.desktop /usr/share/xsessions/awesome.desktop
cp -v ./files/awesome.session /usr/share/gnome-session/sessions/
cp -v ./files/10-awesome.conf /etc/lightdm/lightdm.conf.d/

cp -rv ./files/acpi/ /etc/
