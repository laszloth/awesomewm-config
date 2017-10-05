local hcmd = {}

hcmd.terminal = "konsole"
hcmd.editor = "vim"
hcmd.locker = "light-locker-command -l"
hcmd.calc = "gnome-calculator"

hcmd.jack = "cat /proc/asound/card1/codec#0 | grep 'Pin-ctls:' | head -3 | tail -1 | grep -c OUT"
hcmd.ismuted = "pactl list sinks | grep \"^\\s\\+Mute: yes\" | awk '{print $2}'"
hcmd.volume = {"bash", "-c", "pactl list sinks | grep \"^\\s\\+Volume\" | awk '{print $5}' | tr -d '%'"}
hcmd.backlight = {"bash", "-c", "xbacklight -get"}
hcmd.battery = {"bash", "-c", "cat /sys/class/power_supply/BAT0/capacity"}
hcmd.aconline = "cat /sys/class/power_supply/AC/online"
hcmd.onlaptop = "laptop-detect; echo $?"
hcmd.corecount = "awk '/cpu cores/ {print $4; exit;}' /proc/cpuinfo"

hcmd.play = "~/.config/awesome/scripts/XF86Play.sh"
hcmd.next = "dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next"
hcmd.prev = "dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous"
hcmd.togglemute = "pactl set-sink-mute 0 toggle"
hcmd.lowervol = "pactl set-sink-volume 0 -2%"
hcmd.raisevol = "pactl set-sink-volume 0 +2%"

hcmd.toggletp = "~/.config/awesome/scripts/dell_touch.sh"
hcmd.brightdown = "xbacklight -dec 10"
hcmd.brightup = "xbacklight -inc 10"

return hcmd
