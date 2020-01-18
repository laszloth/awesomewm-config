local hcmd = {}

hcmd.terminal   = "konsole"
hcmd.editor     = "vim"
hcmd.locker     = "light-locker-command -l"
hcmd.calculator = "gnome-calculator"

-- get commands
hcmd.g_aconline = [[cat /sys/class/power_supply/AC/online]]
hcmd.g_onlaptop = [[laptop-detect; echo $?]]
hcmd.g_corecnt  = [[awk '/cpu cores/ {print $4; exit;}' /proc/cpuinfo]]
hcmd.g_netdevs  = [[ls /sys/class/net/]]
hcmd.g_product  = [[cat /sys/devices/virtual/dmi/id/product_name]]

-- raw commands
local _bash       = [[nice -n -20 bash -c ']]
local _sh         = [[nice -n -20 sh -c ']]
local _and        = [[; ret=$?; [ $ret -ne 0 ] && exit $ret;]]
local _terminate  = [[']]

local _soundinfo  = [[~/.config/awesome/scripts/sound_handler.sh --raw]]
local _setvolume  = [[~/.config/awesome/scripts/sound_handler.sh --set-volume ARG1]]
local _setgetvol  = [[~/.config/awesome/scripts/sound_handler.sh --set-get-volume ARG1]]
local _togglemute = [[~/.config/awesome/scripts/sound_handler.sh --toggle-mute]]

local _getbackl   = [[xbacklight -get]]
local _decbackl   = [[xbacklight -dec ARG1 >/dev/null 2>&1]]
local _incbackl   = [[xbacklight -inc ARG1 >/dev/null 2>&1]]
local _battery    = [[cat /sys/class/power_supply/BAT0/capacity]]
local _toggletp   = [[~/.config/awesome/scripts/dell_touch.sh >/dev/null 2>&1]]

local _play       = [[~/.config/awesome/scripts/XF86Play.sh >/dev/null 2>&1]]
local _pause      = [[~/.config/awesome/scripts/spotify_dbus.sh c Pause >/dev/null 2>&1]]
local _next       = [[~/.config/awesome/scripts/spotify_dbus.sh c Next >/dev/null 2>&1]]
local _prev       = [[~/.config/awesome/scripts/spotify_dbus.sh c Previous >/dev/null 2>&1]]
local _mpstatus   = [[~/.config/awesome/scripts/spotify_dbus.sh q PlaybackStatus]]

-- get commands w/ shell
hcmd.g_soundinfo = _bash .. _soundinfo .. _terminate
hcmd.g_backlight = _sh .. _getbackl .. _terminate
hcmd.g_battery   = _sh .. _battery .. _terminate
hcmd.g_mpstatus  = _sh .. _mpstatus .. _terminate

-- set commands w/ shell
hcmd.s_volume     = _bash .. _setvolume .. _terminate
hcmd.s_playtoggle = _sh .. _play .. _terminate
hcmd.s_pause      = _sh .. _pause .. _terminate
hcmd.s_next       = _sh .. _next .. _terminate
hcmd.s_prev       = _sh .. _prev .. _terminate
hcmd.s_toggletp   = _sh .. _toggletp .. _terminate

-- set-get commands for syncronization and speed
hcmd.sg_volume     = _bash .. _setgetvol .. _terminate
hcmd.sg_togglemute = _sh .. _togglemute .. _and .. _soundinfo .. _terminate
hcmd.sg_brightdown = _sh .. _decbackl .. _and .. _getbackl .. _terminate
hcmd.sg_brightup   = _sh .. _incbackl .. _and .. _getbackl .. _terminate

return hcmd

-- vim: autoindent tabstop=8 shiftwidth=4 expandtab softtabstop=4 filetype=lua
