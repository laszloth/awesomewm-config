local awful = require("awful")

local helpmod = {}

helpmod.cmd = require("helpmod.helpmod-cmd")
helpmod.cfg = require("helpmod.helpmod-cfg")

-- will be called in async callback
function helpmod.isJackPlugged()
    local h = assert(io.popen(helpmod.cmd.jack))
    local ret = h:read("*n")
    h:close()
    return ret == 0
end

-- will be called in async callback
function helpmod.isMuted()
    local ret = 0
    local h = assert(io.popen(helpmod.cmd.ismuted))
    if h:read("*l") == "yes" then
        ret = 1
    end
    h:close()
    return ret == 1
end

function helpmod.freshVolumeBox(box)
    awful.spawn.easy_async(helpmod.cmd.volume, function(stdout, stderr, reason, exit_code)
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
            box.markup = '<span foreground="'..helpmod.cfg.volume_mute_color..'">'..pref..vol..'</span>'
        elseif vol >= helpmod.cfg.volume_high then
            box.markup = '<span foreground="'..helpmod.cfg.volume_high_color..'">'..pref..vol..'</span>'
        elseif vol >= helpmod.cfg.volume_mid then
            box.markup = '<span foreground="'..helpmod.cfg.volume_mid_color..'">'..pref..vol..'</span>'
        else
            box.markup = pref..vol
        end
    end)
end

function helpmod.freshBacklightBox(box)
    awful.spawn.easy_async(helpmod.cmd.backlight, function(stdout, stderr, reason, exit_code)
        local pref = 'backlight: '
        if exit_code ~= 0 then
            box.markup = "err"
            return
        end
        box.visible = true
        box.markup = helpmod.cfg.separtxt..pref..
            '<span foreground="'..helpmod.cfg.warn_color..'">'..math.floor(tonumber(stdout))..'</span>'
    end)
end

function helpmod.freshBatteryBox(box, timer)
    awful.spawn.easy_async(helpmod.cmd.battery, function(stdout, stderr, reason, exit_code)
        if exit_code ~= 0 then
            box.markup = "no battery"
            if timer.started then timer:stop() end
            return
        end

        local cap = tonumber(stdout)

        -- workaround for capacity containing 100+ value
        if cap > 100 then cap = 100 end

        local h = assert(io.popen(helpmod.cmd.aconline))
        local ac = h:read("*n")
        h:close()
        if ac == 0 then
            if cap <= helpmod.cfg.battery_low then
                box.markup = '<span foreground="'..helpmod.cfg.battery_low_color..'">B:'..cap..'</span>'
            else
                box.markup = "B:"..cap
            end
        else
            box.markup = '<span foreground="'..helpmod.cfg.battery_charge_color..'">B:'..cap..'</span>'
        end
    end)
end

function helpmod.getNetworkStats(widget,args)
    local text=""
    for i = 1, #helpmod.cfg.net_devices do
      local ndev = helpmod.cfg.net_devices[i]
      if args["{"..ndev.." carrier}"] == 1 then
          local upv = args['{'..ndev..' up_kb}']
          local dnv = args['{'..ndev..' down_kb}']
          local upunit = "K"
          local dnunit = "K"

          if tonumber(upv) >= helpmod.cfg.klimit then
            upunit = "M"
            upv = args['{'..ndev..' up_mb}']
          end

          if tonumber(dnv) >= helpmod.cfg.klimit then
            dnunit = "M"
            dnv = args['{'..ndev..' down_mb}']
          end

          local upspeed = upv..' '..upunit
          local dnspeed = dnv..' '..dnunit
          text=text..'|'..ndev..':<span color="'..helpmod.cfg.net_download_color..'"> down: '..dnspeed..'</span> <span color="'..helpmod.cfg.net_upload_color..'">up: '..upspeed..'</span>'
      end
    end

    if string.len(text)>0 then
        return string.sub(text,2,-1)
    end

    return 'No network'
end

function helpmod.getCoreTempText(temp, n)
    local label = 'Core ' ..(n-2).. ': '
    if temp <= helpmod.cfg.cpu_temp_mid then
        label = label..'<span color="'..helpmod.cfg.cpu_temp_low_color..'">'
    elseif temp <= helpmod.cfg.cpu_temp_high  then
        label = label..'<span color="'..helpmod.cfg.cpu_temp_medium_color..'">'
    else
        label = label..'<span color="'..helpmod.cfg.cpu_temp_high_color..'">'
    end
    return label..temp..'°C</span>'
end

-- called once at startup, popen is fine for now
function helpmod.onLaptop()
    local h = assert(io.popen(helpmod.cmd.onlaptop))
    local ret = h:read("*n")
    h:close()
    return ret == 0
end

-- called once at startup, popen is fine for now
function helpmod.getCPUCoreCnt()
    local h = assert(io.popen(helpmod.cmd.corecount))
    local num = h:read("*n")
    h:close()
    return num
end

return helpmod