local hcmd = {}

hcmd.terminal = "konsole"
hcmd.editor = "vim"
hcmd.locker = "light-locker-command -l"
hcmd.calc = "gnome-calculator"

-- get commands
hcmd.g_aconline = [[cat /sys/class/power_supply/AC/online]]
hcmd.g_onlaptop = [[laptop-detect; echo $?]]
hcmd.g_corecnt = [[awk '/cpu cores/ {print $4; exit;}' /proc/cpuinfo]]
hcmd.g_netdevs = [[ls /sys/class/net/]]

-- raw commands
local _soundinfo = [[~/.config/awesome/scripts/sound_handler.sh raw]]
local _togglemute = [[pactl set-sink-mute 0 toggle >/dev/null 2>&1]]

local _backlight = [[xbacklight -get]]
local _battery = [[cat /sys/class/power_supply/BAT0/capacity]]
local _play = [[~/.config/awesome/scripts/XF86Play.sh >/dev/null 2>&1]]
local _next = [[~/.config/awesome/scripts/spotify_dbus.sh c Next >/dev/null 2>&1]]
local _prev = [[~/.config/awesome/scripts/spotify_dbus.sh c Previous >/dev/null 2>&1]]
local _mpstatus = [[~/.config/awesome/scripts/spotify_dbus.sh q PlaybackStatus]]
local _toggletp = [[~/.config/awesome/scripts/dell_touch.sh >/dev/null 2>&1]]

-- additional conf.
local bl_step = 7 --percent
local vol_step = 2 --percent

-- get commands w/ shell
hcmd.g_soundinfo = {"sh", "-c", _soundinfo}
hcmd.g_backlight = {"sh", "-c", _backlight}
hcmd.g_battery = {"sh", "-c", _battery}
hcmd.g_mpstatus = {"sh", "-c", _mpstatus}

-- set commands w/ shell
hcmd.s_playtoggle = {"sh", "-c", _play}
hcmd.s_next = {"sh", "-c", _next}
hcmd.s_prev = {"sh", "-c", _prev}
hcmd.s_toggletp = {"sh", "-c", _toggletp}

-- set-get commands for syncronization
hcmd.sg_lowervol = {"sh", "-c", "pactl set-sink-volume 0 -"..vol_step.."% >/dev/null 2>&1;".._soundinfo}
hcmd.sg_raisevol = {"sh", "-c", "pactl set-sink-volume 0 +"..vol_step.."% >/dev/null 2>&1;".._soundinfo}
hcmd.sg_togglemute = {"sh", "-c", _togglemute..';'.._soundinfo}
hcmd.sg_brightdown = {"sh", "-c", "xbacklight -dec "..bl_step.." >/dev/null 2>&1;".._backlight}
hcmd.sg_brightup = {"sh", "-c", "xbacklight -inc "..bl_step.." >/dev/null 2>&1;".._backlight}

return hcmd
