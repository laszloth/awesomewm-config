local awful = require("awful")
local helpmod = {}

helpmod.net_devices = { "eno1", "wlp3s0" }

helpmod.warn_color              = '#FECA00'
helpmod.crit_color              = '#FF0000'

helpmod.net_download_color      = '#CC9933'
helpmod.net_upload_color        = '#7F9F7F'
helpmod.klimit                  = 1024

helpmod.cpu_temp_low_color      = '#7FAE5A'
helpmod.cpu_temp_medium_color   = helpmod.warn_color
helpmod.cpu_temp_high_color     = helpmod.crit_color
helpmod.cpu_temp_high           = 85
helpmod.cpu_temp_mid            = 55

helpmod.volume_high             = 65
helpmod.volume_mid              = 40
helpmod.volume_high_color       = helpmod.crit_color
helpmod.volume_mid_color        = helpmod.warn_color
helpmod.volume_mute_color       = '#5C5C5C'

helpmod.battery_low             = 15
helpmod.battery_low_color       = helpmod.crit_color
helpmod.battery_charge_color    = '#7FAE5A'

helpmod.spacetxt = ' '
helpmod.spacetxt2 = '  '
helpmod.spacetxt3 = '   '
helpmod.separtxt = ' | '

function helpmod.isJackPlugged()
    local jackcmd = "cat /proc/asound/card1/codec#0 | grep 'Pin-ctls:'" ..
                "| head -3 | tail -1 | grep -c OUT"
    -- will be called in async callback
    local h = assert(io.popen(jackcmd))
    local ret = h:read("*n")
    h:close()
    return ret == 0
end

function helpmod.isMuted()
    local mutedcmd = "pactl list sinks | grep \"^\\s\\+Mute: yes\" | awk '{print $2}'"
    local ret = 0
    -- will be called in async callback
    local h = assert(io.popen(mutedcmd))
    if h:read("*l") == "yes" then
        ret = 1
    end
    h:close()
    return ret == 1
end

function helpmod.freshVolumeBox(box)
    local volcmd = {"bash", "-c", "pactl list sinks | grep \"^\\s\\+Volume\" | awk '{print $5}' | tr -d '%'"}
    awful.spawn.easy_async(volcmd, function(stdout, stderr, reason, exit_code)
        if exit_code ~= 0 then
            box.markup = "err"
            return
        end

        local vol = tonumber(stdout)
        local pref = 'SPKR:'

        if helpmod.isJackPlugged() then
            pref = 'JACK:'
        end

        if helpmod.isMuted() then
            pref = 'MUTED:'
            box.markup = '<span foreground="'..helpmod.volume_mute_color..'">'..pref..vol..'</span>'
        elseif vol >= helpmod.volume_high then
            box.markup = '<span foreground="'..helpmod.volume_high_color..'">'..pref..vol..'</span>'
        elseif vol >= helpmod.volume_mid then
            box.markup = '<span foreground="'..helpmod.volume_mid_color..'">'..pref..vol..'</span>'
        else
            box.markup = pref..vol
        end
    end)
end

function helpmod.freshBacklightBox(box)
    local blcmd = {"bash", "-c", "xbacklight -get"}
    local pref = 'backlight: '
    awful.spawn.easy_async(blcmd, function(stdout, stderr, reason, exit_code)
        if exit_code ~= 0 then
            box.markup = "err"
            return
        end
        box.visible = true
        box.markup = helpmod.separtxt..pref..
            '<span foreground="'..helpmod.warn_color..'">'..math.floor(tonumber(stdout))..'</span>'
    end)
end

function helpmod.freshBatteryBox(box, timer)
    local batcmd = {"bash", "-c", "cat /sys/class/power_supply/BAT0/capacity"}

    awful.spawn.easy_async(batcmd, function(stdout, stderr, reason, exit_code)
        if exit_code ~= 0 then
            box.markup = "no battery"
            if timer.started then timer:stop() end
            return
        end

        local cap = tonumber(stdout)
        local accmd = "cat /sys/class/power_supply/AC/online"

        -- workaround for capacity containing 100+ value
        if cap > 100 then cap = 100 end

        local h = assert(io.popen(accmd))
        local ac = h:read("*n")
        h:close()
        if ac == 0 then
            if cap <= helpmod.battery_low then
                box.markup = '<span foreground="'..helpmod.battery_low_color..'">B:'..cap..'</span>'
            else
                box.markup = "B:"..cap
            end
        else
            box.markup = '<span foreground="'..helpmod.battery_charge_color..'">B:'..cap..'</span>'
        end
    end)
end

function helpmod.getNetworkStats(widget,args)
    local text=""
    for i = 1, #helpmod.net_devices do
      local ndev = helpmod.net_devices[i]
      if args["{"..ndev.." carrier}"] == 1 then
          local upv = args['{'..ndev..' up_kb}']
          local dnv = args['{'..ndev..' down_kb}']
          local upunit = "K"
          local dnunit = "K"

          if tonumber(upv) >= helpmod.klimit then
            upunit = "M"
            upv = args['{'..ndev..' up_mb}']
          end

          if tonumber(dnv) >= helpmod.klimit then
            dnunit = "M"
            dnv = args['{'..ndev..' down_mb}']
          end

          local upspeed = upv..' '..upunit
          local dnspeed = dnv..' '..dnunit
          text=text..'|'..ndev..':<span color="'..helpmod.net_download_color..'"> down: '..dnspeed..'</span> <span color="'..helpmod.net_upload_color..'">up: '..upspeed..'</span>'
      end
    end

    if string.len(text)>0 then
        return string.sub(text,2,-1)
    end

    return 'No network'
end

function helpmod.getCoreTempText(temp, n)
    local label = 'Core ' ..(n-2).. ': '
    if temp <= helpmod.cpu_temp_mid then
        label = label..'<span color="'..helpmod.cpu_temp_low_color..'">'
    elseif temp <= helpmod.cpu_temp_high  then
        label = label..'<span color="'..helpmod.cpu_temp_medium_color..'">'
    else
        label = label..'<span color="'..helpmod.cpu_temp_high_color..'">'
    end
    return label..temp..'°C</span>'
end

-- called once at startup, popen is fine for now
function helpmod.onLaptop()
    local h = assert(io.popen("laptop-detect; echo $?"))
    local ret = h:read("*n")
    h:close()
    return ret == 0
end

-- called once at startup, popen is fine for now
function helpmod.getCPUCoreCnt()
    local corecmd = "awk '/cpu cores/ {print $4; exit;}' /proc/cpuinfo"
    local h = assert(io.popen(corecmd))
    local num = h:read("*n")
    h:close()
    return num
end

return helpmod
