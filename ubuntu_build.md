# build steps on Ubuntu 16.04.3 LTS

## deps, maybe not all needed
 - sudo apt install cmake libgdk-pixbuf2.0-dev libcairo2-dev libxcb-cursor-dev libxcb-randr0-dev libxcb-xtest0-dev libxcb-xinerama0-dev libxcb-shape0-dev libxcb-util-dev libxcb-keysyms1-dev libxcb-icccm4-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libstartup-notification0-dev libxdg-basedir-dev libxcb-xrm-dev

## dbus support
 - sudo apt install libdbus-1-dev

## lua 5.3.4 compilation & install
 - http://www.lua.org/ftp/lua-5.3.4.tar.gz
 - make linux test
 - sudo make INSTALL_TOP=/usr/local install

## lgi 0.9.2 deps, compilation & install
 - https://github.com/pavouk/lgi/archive/0.9.2.tar.gz
 - sudo apt-get install libgirepository1.0-dev
 - make LUA_VERSION=5.3
 - sudo make PREFIX=/usr/local LUA_VERSION=5.3 install

## awesome 4.2 compilation & install
 - https://github.com/awesomeWM/awesome/releases/download/v4.2/awesome-4.2.tar.bz2
 - or git clone git@github.com:awesomeWM/awesome.git
 - CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=/usr/local" make
 - make package
 - sudo dpkg -i build/awesome-<version>-Linux.deb

## vicious
 - https://github.com/Mic92/vicious/archive/v2.3.1.tar.gz
 - untar to /usr/local/lib/lua/5.3/vicious
