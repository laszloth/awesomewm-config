local awful = require("awful")

local helpmod = {}
helpmod.cmd = require("helpmod.helpmod-cmd")
helpmod.cfg = require("helpmod.helpmod-cfg")

-- {{{ Private
local prev_batt_level = 100

local function _get_sound_info(script_output)
    local sound_info = {}
    local rawdata = helpmod.str_to_table(script_output, "%s")
    sound_info["sink_index"] = tonumber(rawdata[1])
    sound_info["is_muted"] = (tonumber(rawdata[2]) == 1)
    sound_info["volume"] = tonumber(rawdata[3])
    sound_info["bus_type"] = rawdata[4]
    sound_info["jack_plugged"] = (tonumber(rawdata[5]) == 1)
    return sound_info
end
-- }}}

function helpmod.fresh_mpstate_box(boxes, imgs)
    awful.spawn.easy_async(helpmod.cmd.g_mpstatus, function(stdout, stderr, reason, exit_code)
        if exit_code ~= 0 then
            for i = 1, #boxes do
                --debug_print("MP_stderr="..stderr)
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

function helpmod.fresh_volume_box(box, run_cmd)
    local cmd = run_cmd or helpmod.cmd.g_soundinfo
    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        --debug_print_perm("cmd='"..cmd[#cmd].."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        if exit_code ~= 0 then
            --debug_print("VB_stderr="..stderr)
            box.markup = "<error>"
            return
        end

        local sinfo = _get_sound_info(stdout)
        local isusb = (sinfo.bus_type == "usb")
        local vol = sinfo.volume

        local pref = helpmod.cfg.label_speaker
        if isusb then
            pref = helpmod.cfg.label_usb
        elseif sinfo.jack_plugged then
            pref = helpmod.cfg.label_jack
        end

        if sinfo.is_muted then
            pref = helpmod.cfg.label_muted
            box.markup = '<span foreground="'..helpmod.cfg.volume_mute_color..'">'..pref..vol..'</span>'
        -- no different level colors for usb card as 100% is the normal volume
        elseif not isusb then
            if vol >= helpmod.cfg.volume_high then
                box.markup = '<span foreground="'..helpmod.cfg.volume_high_color..'">'..pref..vol..'</span>'
            elseif vol >= helpmod.cfg.volume_mid then
                box.markup = '<span foreground="'..helpmod.cfg.volume_mid_color..'">'..pref..vol..'</span>'
            else
                box.markup = pref..vol
            end
        else
            box.markup = '<span foreground="'..helpmod.cfg.usb_card_color..'">'..pref..vol..'</span>'
        end
    end)
end

function helpmod.fresh_backlight_box(box, run, run_cmd)
    local cmd = helpmod.cmd.g_backlight
    if run then
        cmd = run_cmd
    end
    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        --debug_print_perm("cmd='"..cmd[#cmd].."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        local pref = 'backlight: '
        if exit_code ~= 0 then
            --debug_print("BL_stderr="..stderr)
            box.markup = "<error>"
            return
        end
        box.visible = true
        box.markup = helpmod.cfg.separ_txt..pref..
            '<span foreground="'..helpmod.cfg.warn_color..'">'..math.floor(tonumber(stdout))..'</span>'
    end)
end

function helpmod.fresh_battery_box(box, timer)
    awful.spawn.easy_async(helpmod.cmd.g_battery, function(stdout, stderr, reason, exit_code)
        --debug_print_perm("cmd='"..cmd[#cmd].."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        if exit_code ~= 0 then
            --debug_print("BB_stderr="..stderr)
            box.markup = "no battery"
            if timer.started then timer:stop() end
            return
        end

        local cap = tonumber(stdout)
        local h = assert(io.popen(helpmod.cmd.g_aconline))
        local ac = h:read("*n")
        h:close()
        if ac == 0 then
            if cap <= helpmod.cfg.battery_low then
                box.markup = '<span foreground="'..helpmod.cfg.battery_low_color..'">B:'..cap..'</span>'
                if cap < prev_batt_level and math.fmod(cap, helpmod.cfg.battery_low_notif_gap) == 0 then
                    prev_batt_level = cap
                    warn_print("low battery: "..cap.."%")
                end
            else
                box.markup = "B:"..cap
            end
        else
            box.markup = '<span foreground="'..helpmod.cfg.battery_charge_color..'">B:'..cap..'</span>'
        end
    end)
end

function helpmod.get_network_stats(widget, args, netdevs)
    local up_unit = "K"
    local down_unit = "K"
    local down_label = "Rx"
    local up_label = "Tx"
    local text = ""

    for i = 1, #netdevs do
        local nwdev = netdevs[i]
        if args["{"..nwdev.." carrier}"] == 1 then
            local up_val = args['{'..nwdev..' up_kb}']
            local down_val = args['{'..nwdev..' down_kb}']

            if tonumber(up_val) >= helpmod.cfg.kilo_limit then
                up_unit = "M"
                up_val = args['{'..nwdev..' up_mb}']
            end

            if tonumber(down_val) >= helpmod.cfg.kilo_limit then
                down_unit = "M"
                down_val = args['{'..nwdev..' down_mb}']
            end

            local up_data = up_val..' '..up_unit
            local down_data = down_val..' '..down_unit

            if string.match(nwdev, "tun") then
                nwdev = '<span color="'..helpmod.cfg.net_tunnel_color..'">'..nwdev..':</span>'
            else
                nwdev = nwdev .. ':'
            end
            text = text..' - '..nwdev..'<span color="'..helpmod.cfg.net_download_color..
                    '"> '..down_label..' '..down_data..'</span> / <span color="'..
                    helpmod.cfg.net_upload_color..'">'..up_label..' '..up_data..'</span>'
      end
    end

    -- remove separator
    if string.len(text) > 0 then
        return string.sub(text, 4, -1)
    end

    return 'no network'
end

function helpmod.get_coretemp_text(temp, n)
    local label = 'core ' ..(n-2).. ': '
    if temp <= helpmod.cfg.cpu_temp_mid then
        label = label..'<span color="'..helpmod.cfg.cpu_temp_low_color..'">'
    elseif temp <= helpmod.cfg.cpu_temp_high  then
        label = label..'<span color="'..helpmod.cfg.cpu_temp_medium_color..'">'
    else
        label = label..'<span color="'..helpmod.cfg.cpu_temp_high_color..'">'
    end
    return label..temp..'°C</span>'..helpmod.cfg.separ_txt
end

-- called once at startup, popen is fine for now
function helpmod.is_on_laptop()
    local h = assert(io.popen(helpmod.cmd.g_onlaptop))
    local ret = h:read("*n")
    h:close()
    return ret == 0
end

-- called once at startup, popen is fine for now
function helpmod.get_cpu_core_count()
    local h = assert(io.popen(helpmod.cmd.g_corecnt))
    local num = h:read("*n")
    h:close()
    return num
end

-- called once at startup, popen is fine for now
function helpmod.get_net_devices()
    local h = assert(io.popen(helpmod.cmd.g_netdevs))
    local ret = h:read("*a")
    h:close()
    return helpmod.str_to_table(ret, "%s", "lo")
end

function helpmod.fill_args(raw_cmd, args)
    local cmd
    if type(args) ~= "table" then return end
    for i = 1, #args do
       cmd = string.gsub(raw_cmd, "ARG"..i, args[i])
    end
    return cmd
end

function helpmod.str_to_table(string, delimiter, exclude)
    local arr = {}
    for m in string.gmatch(string, "[^"..delimiter.."]+") do
        if m ~= exclude then table.insert(arr, m) end
    end
    return arr
end

function helpmod.table_to_str(t, depth)
    depth = depth or 0

    if type(t) ~= "table" then
        return tostring(t)
    end

    local dpref = " "
    for i = 1, depth do
        dpref = dpref.." "
    end

    local str = "{ "
    for key, value in pairs(t) do
        str = str.."\n"..dpref.."["..tostring(key).."] = "..
                helpmod.table_to_str(value, depth+1)..", "
    end
    return str.."}"
end

function helpmod.print_table(t, name)
    name = name or "table"
    debug_print(name..' '..helpmod.table_to_str(t))
end

function helpmod.print_table_perm(t, name)
    name = name or "table"
    debug_print_perm(name..' '..helpmod.table_to_str(t))
end

return helpmod
