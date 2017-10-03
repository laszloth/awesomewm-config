# Ubuntu 16.04.3 LTS

# deps, maybe not all needed
sudo apt install cmake libgdk-pixbuf2.0-dev libcairo2-dev libxcb-cursor-dev libxcb-randr0-dev libxcb-xtest0-dev libxcb-xinerama0-dev libxcb-shape0-dev libxcb-util-dev libxcb-keysyms1-dev libxcb-icccm4-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev libstartup-notification0-dev libxdg-basedir-dev libxcb-xrm-dev

# dbus support
sudo apt install libdbus-1-dev

# lua 5.3.4 compilation & install
curl -RO http://www.lua.org/ftp/lua-5.3.4.tar.gz
make linux test
sudo make INSTALL_TOP=/usr/local install

# lgi 0.9.1 deps, compilation & install
sudo apt-get install libgirepository1.0-dev
https://github.com/pavouk/lgi/archive/0.9.1.tar.gz
make LUA_VERSION=5.3
sudo make PREFIX=/usr/local LUA_VERSION=5.3 install

# awesome 4.2 compilation & install
https://github.com/awesomeWM/awesome/releases/download/v4.2/awesome-4.2.tar.bz2
CMAKE_ARGS="-DCMAKE_INSTALL_PREFIX=/usr/local" make
make package
sudo dpkg -i build/awesome-4.2.0.0-Linux.deb

# vicious
https://github.com/Mic92/vicious/archive/v2.2.0.tar.gz
