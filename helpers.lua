local helpers = {}

helpers.net_devices = { 'eno1', 'wlp3s0' }

helpers.warn_color              = '#FECA00'
helpers.crit_color              = '#FF0000'

helpers.prompt_bg               = '#000000'
helpers.prompt_fg               = '#00FF00'

helpers.net_download_color      = '#CC9933'
helpers.net_upload_color        = '#7F9F7F'
helpers.klimit                  = 1024

helpers.cpu_temp_low_color      = "#7FAE5A"
helpers.cpu_temp_medium_color   = helpers.warn_color
helpers.cpu_temp_high_color     = helpers.crit_color
helpers.cpu_temp_high           = 85
helpers.cpu_temp_mid            = 55

helpers.volume_high             = 65
helpers.volume_mid              = 40
helpers.volume_high_color       = helpers.crit_color
helpers.volume_mid_color        = helpers.warn_color
helpers.volume_mute_color       = "#5C5C5C"
helpers.volume_limit            = 80

helpers.battery_low             = 15
helpers.battery_low_color       = helpers.crit_color
helpers.battery_charge_color    = "#7FAE5A"

function helpers.isJackPlugged()
    local jackcmd = "cat /proc/asound/card1/codec#0 | grep 'Pin-ctls:'" ..
                "| head -3 | tail -1 | grep -c OUT"
    local h = assert(io.popen(jackcmd))
    local ret = h:read("*n")
    h:close()
    return 1 - ret
end

function helpers.isMuted()
    local mutedcmd = "pactl list sinks | grep \"^\\s\\+Mute: yes\" | awk '{print $2}'"
    local ret = 0
    local h = assert(io.popen(mutedcmd))
    if h:read("*l") == "yes" then
        ret = 1
    end
    h:close()
    return ret
end

function helpers.getVolumeLevel(raw)
    local volcmd = "pactl list sinks | grep \"^\\s\\+Volume\" | awk '{print $5}'"
    local h = assert(io.popen(volcmd))
    local vol = h:read("*n")
    h:close()

    -- on version update, have to change popen to easy async or with_line_callback
    --awful.spawn.easy_async(volcmd, function(stdout, stderr, reason, exit_code)
    --    naughty.notify { text = stdout }
    --end)

    if raw == 1 then
        return vol
    end

    local pref = 'SPKR:'
    if helpers.isJackPlugged() == 1 then
        pref = 'JACK:'
    end

    if helpers.isMuted() == 1 then
        pref = 'MUTED:'
        return '<span foreground="'..helpers.volume_mute_color..'">'..pref..vol..'</span>'
    elseif vol >= helpers.volume_high then
        return '<span foreground="'..helpers.volume_high_color..'">'..pref..vol..'</span>'
    elseif vol >= helpers.volume_mid then
        return '<span foreground="'..helpers.volume_mid_color..'">'..pref..vol..'</span>'
    else
        return pref..vol
    end
end

function helpers.getBatteryLevel()
    local h = assert(io.popen("cat /sys/class/power_supply/BAT0/capacity"))
    local cap = h:read("*n")
    h:close()

    -- check if battery is present
    if cap == nil then
        return "no battery"
    end

    -- workaround for capacity containing 100+ value
    if cap > 100 then cap = 100 end
    h = assert(io.popen("cat /sys/class/power_supply/AC/online"))
    local ac = h:read("*n")
    h:close()
    if ac == 0 then
        if cap <= helpers.battery_low then
            return '<span foreground="'..helpers.battery_low_color..'">B:'..cap..'</span>'
        else
            return "B:"..cap
        end
    else
        return '<span foreground="'..helpers.battery_charge_color..'">B:'..cap..'</span>'
    end
end

function helpers.getNetworkStats(widget,args)
    local text=""
    for i = 1, #helpers.net_devices do
      local ndev = helpers.net_devices[i]
      if args["{"..ndev.." carrier}"] == 1 then
          local upv = args['{'..ndev..' up_kb}']
          local dnv = args['{'..ndev..' down_kb}']
          local upunit = "K"
          local dnunit = "K"

          if tonumber(upv) >= helpers.klimit then
            upunit = "M"
            upv = args['{'..ndev..' up_mb}']
          end

          if tonumber(dnv) >= helpers.klimit then
            dnunit = "M"
            dnv = args['{'..ndev..' down_mb}']
          end

          local upspeed = upv..' '..upunit
          local dnspeed = dnv..' '..dnunit
          text=text..'|'..ndev..':<span color="'..helpers.net_download_color..'"> down: '..dnspeed..'</span> <span color="'..helpers.net_upload_color..'">up: '..upspeed..'</span>'
      end
    end

    if string.len(text)>0 then
        return string.sub(text,2,-1)
    end

    return 'No network'
end

function helpers.getCoreTempText(t, n)
        local ctemp = tonumber(t)
        local s = 'Core ' ..(n-2).. ': '

        if ctemp <= helpers.cpu_temp_mid then
          s = s..'<span color="'..helpers.cpu_temp_low_color..'">'
        elseif ctemp <= helpers.cpu_temp_high  then
          s = s..'<span color="'..helpers.cpu_temp_medium_color..'">'
        else
          s = s..'<span color="'..helpers.cpu_temp_high_color..'">'
        end

        return s..t..'°C</span>'
end

function helpers.getBacklightLevel()
    local blcmd = "xbacklight -get"
    local h = assert(io.popen(blcmd))
    local bl = h:read("*n")
    h:close()
    return math.floor(bl)
end

return helpers
