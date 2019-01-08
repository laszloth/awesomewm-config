#!/bin/sh

cp -nv ./55awesome-javaworkaround /etc/X11/Xsession.d/

install -v -m 0644 ./awesome.desktop /usr/share/applications/
install -v -m 0644 ./awesome-xsessions.desktop /usr/share/xsessions/awesome.desktop
install -v -m 0644 ./awesome.session /usr/share/gnome-session/sessions/
install -v -m 0644 ./10-awesome.conf /etc/lightdm/lightdm.conf.d/
install -v -m 0644 ./20-sudo-niceness.conf /etc/security/limits.d/

cp -rv ./acpi/ /etc/

echo "done"
