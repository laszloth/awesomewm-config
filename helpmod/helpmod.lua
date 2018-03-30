local helpmod = {}

helpmod.cmd = require("helpmod.helpmod-cmd")
helpmod.cfg = require("helpmod.helpmod-cfg")
helpmod.fnc = require("helpmod.helpmod-fnc")

helpmod.sound_info = {}
helpmod.widgets = {}

-- {{{ Private
local awful = require("awful")
local hcmd = helpmod.cmd
local hcfg = helpmod.cfg
local hfnc = helpmod.fnc

local _prev_batt_lvl = 100

local function _remove_newlines(s)
    return string.gsub(s, "\n", "")
end

local function _fill_args(raw_cmd, args)
    local cmd

    if type(args) ~= "table" then return end
    for i = 1, #args do
       cmd = string.gsub(raw_cmd, "ARG"..i, args[i])
    end

    return cmd
end

local function _parse_sound_info(raw_output)
    local sound_info = {}
    local rawdata = hfnc.str_to_table(raw_output, ";")
    local specs = hfnc.str_to_table(rawdata[7], " ")

    sound_info["sink"] = rawdata[1]
    sound_info["sink_index"] = tonumber(rawdata[2])
    sound_info["volume"] = tonumber(rawdata[3])
    sound_info["is_muted"] = (tonumber(rawdata[4]) == 1)
    sound_info["jack_plugged"] = (tonumber(rawdata[5]) == 1)
    sound_info["bus_type"] = rawdata[6]
    sound_info["sample_specs"] = { bit_depth = specs[1],
                                   channels = specs[2],
                                   sample_rate = specs[3] }

    return sound_info
end

local function _init_usb()
    local default_volume = hcfg.usb_init_val
    local usb_cmd = _fill_args(hcmd.s_volume, { default_volume })
    helpmod.sound_info.volume = default_volume
    awful.util.spawn(usb_cmd)
end

local function _fresh_volume_box(cmd)
    local box = helpmod.widgets.volume.box
    if not box then return end
    cmd = cmd or hcmd.g_soundinfo

    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        --debug_print_perm("cmd='"..cmd[#cmd].."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        if exit_code ~= 0 then
            box.markup = "<error>"
            return
        end

        local prev_bus = helpmod.sound_info.bus_type
        helpmod.sound_info = _parse_sound_info(_remove_newlines(stdout))
        local sinfo = helpmod.sound_info
        local isusb = (sinfo.bus_type == "usb")
        local vol = sinfo.volume

        -- check for bus type change to usb and do setup
        if isusb and prev_bus ~= "usb" then
            _init_usb()
        end

        local pref = hcfg.label_speaker
        if isusb then
            pref = hcfg.label_usb
        elseif sinfo.jack_plugged then
            pref = hcfg.label_jack
        end

        if sinfo.is_muted then
            pref = hcfg.label_muted
            box.markup = '<span foreground="'..hcfg.volume_mute_color..'">'..pref..vol..'</span>'
        -- no different level colors for usb card as 100% is the normal volume
        elseif not isusb then
            if vol >= hcfg.volume_high then
                box.markup = '<span foreground="'..hcfg.volume_high_color..'">'..pref..vol..'</span>'
            elseif vol >= hcfg.volume_mid then
                box.markup = '<span foreground="'..hcfg.volume_mid_color..'">'..pref..vol..'</span>'
            else
                box.markup = pref..vol
            end
        else
            box.markup = '<span foreground="'..hcfg.usb_card_color..'">'..pref..vol..'</span>'
        end
    end)
end

local function _modify_volume(new_volume)
    local cmd = _fill_args(hcmd.sg_volume, { new_volume })
    _fresh_volume_box(cmd)
end

local function _modify_volume_rel(increase)
    local vol = ""

    if increase then vol = "+" else vol = "-" end

    if helpmod.sound_info.bus_type == "usb" then
        vol = vol .. tostring(hcfg.usb_step)
    else
        vol = vol .. tostring(hcfg.vol_step)
    end

    _modify_volume(vol)
end

local function _fresh_mpstate_box()
    local boxes = helpmod.widgets.mpstate.boxes
    local imgs = helpmod.widgets.mpstate.images
    if not ( boxes or imgs ) then return end
    local cmd = hcmd.g_mpstatus

    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        if exit_code ~= 0 then
            for i = 1, #boxes do
                boxes[i].visible = false
            end
            return
        end

        local state = _remove_newlines(stdout)
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

local function _fresh_backlight_box(cmd)
    local box = helpmod.widgets.backlight.box
    if not box then return end
    cmd = cmd or hcmd.g_backlight

    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        --debug_print_perm("cmd='"..cmd[#cmd].."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        local pref = 'backlight: '
        if exit_code ~= 0 then
            box.markup = "<error>"
            return
        end
        box.visible = true
        box.markup = hcfg.separ_txt..pref..
            '<span foreground="'..hcfg.warn_color..'">'..math.floor(tonumber(stdout))..'</span>'
    end)
end

local function _fresh_battery_box()
    local box = helpmod.widgets.battery.box
    local timer = helpmod.widgets.battery.timer
    if not ( box or timer ) then return end
    local cmd = hcmd.g_battery

    awful.spawn.easy_async(cmd, function(stdout, stderr, reason, exit_code)
        --debug_print_perm("cmd='"..cmd[#cmd].."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        if exit_code ~= 0 then
            --debug_print("BB_stderr="..stderr)
            box.markup = "no battery"
            if timer.started then timer:stop() end
            return
        end

        local cap = tonumber(stdout)
        local h = assert(io.popen(hcmd.g_aconline))
        local ac = h:read("*n")
        h:close()
        if ac == 0 then
            if cap <= hcfg.battery_low then
                box.markup = '<span foreground="'..hcfg.battery_low_color..'">B:'..cap..'</span>'
                if cap < _prev_batt_lvl and math.fmod(cap, hcfg.battery_low_notif_gap) == 0 then
                    _prev_batt_lvl = cap
                    warn_print("low battery: "..cap.."%")
                end
            else
                box.markup = "B:"..cap
            end
        else
            box.markup = '<span foreground="'..hcfg.battery_charge_color..'">B:'..cap..'</span>'
        end
    end)
end
-- }}}

function helpmod.lower_volume()
    _modify_volume_rel(false)
end

function helpmod.raise_volume()
    _modify_volume_rel(true)
end

function helpmod.toggle_mute()
    _fresh_volume_box(hcmd.sg_togglemute)
end

function helpmod.fresh_volume_box()
    _fresh_volume_box()
end

function helpmod.fresh_mpstate_box()
    _fresh_mpstate_box()
end

function helpmod.brightness_down()
    local cmd = _fill_args(hcmd.sg_brightdown, { hcfg.bl_step })
    _fresh_backlight_box(cmd)
end

function helpmod.brightness_up()
    local cmd = _fill_args(hcmd.sg_brightup, { hcfg.bl_step })
    _fresh_backlight_box(cmd)
end

function helpmod.fresh_backlight_box()
    _fresh_backlight_box()
end

function helpmod.fresh_battery_box()
    _fresh_battery_box()
end

function helpmod.get_network_stats(widget, args, netdevs)
    local up_unit = "K"
    local down_unit = "K"
    local down_label = "Rx"
    local up_label = "Tx"
    local dec_places = hcfg.nw_decimal_places
    local kilo = 1024
    local text = ""

    for i = 1, #netdevs do
        local nwdev = netdevs[i]
        if args["{"..nwdev.." carrier}"] == 1 then
            local down_val = tonumber(args['{'..nwdev..' down_b}']) / kilo
            local up_val = tonumber(args['{'..nwdev..' up_b}']) / kilo
            local down_str = ""
            local up_str = ""


            if down_val >= kilo then
                down_unit = "M"
                down_val = down_val / kilo
            end
            if up_val >= kilo then
                up_unit = "M"
                up_val = up_val / kilo
            end

            down_val = hfnc.round(down_val, dec_places)
            up_val = hfnc.round(up_val, dec_places)
            down_str = hfnc.add_decimal_padding(down_val, dec_places) .. ' ' .. down_unit
            up_str = hfnc.add_decimal_padding(up_val, dec_places) .. ' ' .. up_unit

            if string.match(nwdev, "tun") then
                nwdev = '<span color="' .. hcfg.net_tunnel_color .. '">' .. nwdev .. ':</span>'
            else
                nwdev = nwdev .. ':'
            end
            text = text..' - '..nwdev..'<span color="'..hcfg.net_download_color..
                    '"> '..down_label..' '..down_str..'</span> / <span color="'..
                    hcfg.net_upload_color..'">'..up_label..' '..up_str..'</span>'
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

    if temp <= hcfg.cpu_temp_mid then
        label = label..'<span color="'..hcfg.cpu_temp_low_color..'">'
    elseif temp <= hcfg.cpu_temp_high  then
        label = label..'<span color="'..hcfg.cpu_temp_medium_color..'">'
    else
        label = label..'<span color="'..hcfg.cpu_temp_high_color..'">'
    end

    return label..temp..'°C</span>'..hcfg.separ_txt
end

-- called once at startup, popen is fine for now
function helpmod.is_on_laptop()
    local h = assert(io.popen(hcmd.g_onlaptop))
    local ret = h:read("*n")
    h:close()
    return ret == 0
end

-- called once at startup, popen is fine for now
function helpmod.get_cpu_core_count()
    local h = assert(io.popen(hcmd.g_corecnt))
    local num = h:read("*n")
    h:close()
    return num
end

-- called once at startup, popen is fine for now
function helpmod.get_net_devices()
    local h = assert(io.popen(hcmd.g_netdevs))
    local ret = h:read("*a")
    h:close()
    return hfnc.str_to_table(ret, "%s", "lo")
end

-- called once at startup/in callback, popen is fine for now
function helpmod.init_sound()
    local h = assert(io.popen(hcmd.g_soundinfo))
    local ret = h:read("*a")

    h:close()

    helpmod.sound_info = _parse_sound_info(_remove_newlines(ret))
    --hfnc.print_table_perm(helpmod.sound_info, "sinfo")
    if helpmod.sound_info.bus_type == "usb" then
        _init_usb()
    end

    return
end

return helpmod
