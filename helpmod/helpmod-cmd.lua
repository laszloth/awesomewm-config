local hcmd = {}

hcmd.terminal = "konsole"
hcmd.editor = "vim"
hcmd.locker = "light-locker-command -l"
hcmd.calc = "gnome-calculator"

-- get commands
hcmd.g_jack = [[cat /proc/asound/card1/codec#0 | grep 'Pin-ctls:' | head -3 | tail -1 | grep -c OUT]]
hcmd.g_ismuted = [[pactl list sinks | grep "^\s\+Mute: yes" | awk '{print $2}']]
hcmd.g_aconline = [[cat /sys/class/power_supply/AC/online]]
hcmd.g_onlaptop = [[laptop-detect; echo $?]]
hcmd.g_corecnt = [[awk '/cpu cores/ {print $4; exit;}' /proc/cpuinfo]]

-- raw commands
local _volume = [[pactl list sinks | grep "^\s\+Volume" | awk '{print $5}' | tr -d '%']]
local _backlight = [[xbacklight -get]]
local _battery = [[cat /sys/class/power_supply/BAT0/capacity]]
local _play = [[~/.config/awesome/scripts/XF86Play.sh >/dev/null 2>&1]]
local _next = [[~/.config/awesome/scripts/spotify_dbus.sh c Next >/dev/null 2>&1]]
local _prev = [[~/.config/awesome/scripts/spotify_dbus.sh c Previous >/dev/null 2>&1]]
local _mpstatus = [[~/.config/awesome/scripts/spotify_dbus.sh q PlaybackStatus]]
local _togglemute = [[pactl set-sink-mute 0 toggle >/dev/null 2>&1]]
local _toggletp = [[~/.config/awesome/scripts/dell_touch.sh >/dev/null 2>&1]]

-- get commands w/ shell
hcmd.g_volume = {"sh", "-c", _volume}
hcmd.g_backlight = {"sh", "-c", _backlight}
hcmd.g_battery = {"sh", "-c", _battery}
hcmd.g_mpstatus = {"sh", "-c", _mpstatus}

-- set commands w/ shell
hcmd.s_playtoggle = {"sh", "-c", _play}
hcmd.s_next = {"sh", "-c", _next}
hcmd.s_prev = {"sh", "-c", _prev}
hcmd.s_toggletp = {"sh", "-c", _toggletp}

-- set-get commands for syncronization
hcmd.sg_lowervol = {"sh", "-c", "pactl set-sink-volume 0 -2% >/dev/null 2>&1;".._volume}
hcmd.sg_raisevol = {"sh", "-c", "pactl set-sink-volume 0 +2% >/dev/null 2>&1;".._volume}
hcmd.sg_togglemute = {"sh", "-c", _togglemute..';'.._volume}
hcmd.sg_brightdown = {"sh", "-c", "xbacklight -dec 10 >/dev/null 2>&1;".._backlight}
hcmd.sg_brightup = {"sh", "-c", "xbacklight -inc 10 >/dev/null 2>&1;".._backlight}

return hcmd
