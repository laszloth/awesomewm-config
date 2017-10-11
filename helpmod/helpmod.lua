local awful = require("awful")

local helpmod = {}

helpmod.cmd = require("helpmod.helpmod-cmd")
helpmod.cfg = require("helpmod.helpmod-cfg")

-- will be called in async callback
function helpmod.isJackPlugged()
    local h = assert(io.popen(helpmod.cmd.g_jack))
    local ret = h:read("*n")
    h:close()
    return ret == 0
end

-- will be called in async callback
function helpmod.isMuted()
    local ret = 0
    local h = assert(io.popen(helpmod.cmd.g_ismuted))
    if h:read("*l") == "yes" then
        ret = 1
    end
    h:close()
    return ret == 1
end

function helpmod.freshMPStateBox(boxes, imgs, run, run_cmd)
    local cmd = helpmod.cmd.g_mpstatus
    if run then
        cmd = run_cmd
    end
    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        --debug_print_perm("cmd='"..cmd[#cmd].."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        if exit_code ~= 0 then
            for i = 1, #boxes do
                boxes[i].visible = false
            end
            return
        end

        local state = string.gsub(stdout, "\n", "")
        if state == "Playing" then
            boxes[1].image = imgs[1]
        else
            boxes[1].image = imgs[2]
        end
        for i = 1, #boxes do
            boxes[i].visible = true
        end
    end)
end

function helpmod.freshVolumeBox(box, run, run_cmd)
    local cmd = helpmod.cmd.g_volume
    if run then
        cmd = run_cmd
    end
    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        --debug_print_perm("cmd='"..cmd[#cmd].."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
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

function helpmod.freshBacklightBox(box, run, run_cmd)
    local cmd = helpmod.cmd.g_backlight
    if run then
        cmd = run_cmd
    end
    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        --debug_print_perm("cmd='"..cmd[#cmd].."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
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
    awful.spawn.easy_async(helpmod.cmd.g_battery, function(stdout, stderr, reason, exit_code)
        --debug_print_perm("cmd='"..cmd[#cmd].."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        if exit_code ~= 0 then
            box.markup = "no battery"
            if timer.started then timer:stop() end
            return
        end

        local cap = tonumber(stdout)

        -- workaround for capacity containing 100+ value
        if cap > 100 then cap = 100 end

        local h = assert(io.popen(helpmod.cmd.g_aconline))
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

function helpmod.getNetworkStats(widget, args)
    local text = ""
    for i = 1, #helpmod.cfg.net_devices do
        local nwdev = helpmod.cfg.net_devices[i]
        if args["{"..nwdev.." carrier}"] == 1 then
            local up_val = args['{'..nwdev..' up_kb}']
            local down_val = args['{'..nwdev..' down_kb}']
            local up_unit = "K"
            local down_unit = "K"

            if tonumber(up_val) >= helpmod.cfg.klimit then
                up_unit = "M"
                up_val = args['{'..nwdev..' up_mb}']
            end

            if tonumber(down_val) >= helpmod.cfg.klimit then
                down_unit = "M"
                down_val = args['{'..nwdev..' down_mb}']
            end

            local up_label = up_val..' '..up_unit
            local down_label = down_val..' '..down_unit

            text = text..' - '..nwdev..':<span color="'..helpmod.cfg.net_download_color..
                '"> down: '..down_label..'</span> <span color="'..helpmod.cfg.net_upload_color..
                '">up: '..up_label..'</span>'
      end
    end

    -- remove separator
    if string.len(text) > 0 then
        return string.sub(text, 4, -1)
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
    return label..temp..'°C</span>'..helpmod.cfg.separtxt
end

-- called once at startup, popen is fine for now
function helpmod.onLaptop()
    local h = assert(io.popen(helpmod.cmd.g_onlaptop))
    local ret = h:read("*n")
    h:close()
    return ret == 0
end

-- called once at startup, popen is fine for now
function helpmod.getCPUCoreCnt()
    local h = assert(io.popen(helpmod.cmd.g_corecnt))
    local num = h:read("*n")
    h:close()
    return num
end

return helpmod
