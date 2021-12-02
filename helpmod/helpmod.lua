local helpmod = {}

helpmod.cmd = require("helpmod.helpmod-cmd")
helpmod.cfg = require("helpmod.helpmod-cfg")
helpmod.fnc = require("helpmod.helpmod-fnc")

helpmod.sound_info = {}
helpmod.widgets = {}

helpmod.t_bus = {
    pci = "PCI",
    usb = "USB",
    bluetooth = "BLUETOOTH",
}

-- {{{ Private
local awful = require("awful")
local hcmd = helpmod.cmd
local hcfg = helpmod.cfg
local hfnc = helpmod.fnc

local t_bus = helpmod.t_bus

local _sound_info_skel = {
  { "sink_index",    "number"  },
  { "sink",          "string"  },
  { "volume",        "number"  },
  { "is_muted",      "boolean" },
  { "jack_plugged",  "boolean" },
  { "bus_type",      "string"  },
  { "bit_depth",     "string"  },
  { "channels",      "number"  },
  { "sample_rate",   "number"  },
  { "has_vol_ctrl",  "boolean" },
}

local _req_sound_info_count = #_sound_info_skel
local _prev_states = { mp = nil, bat = 100, vol = 0 }

local function _remove_newline(s)
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
    local rawdata = hfnc.str_to_table(raw_output, ";")
    local sound_info = {}

    for i = 1, _req_sound_info_count do
        local elem = _sound_info_skel[i]
        local elem_name = elem[1]
        local elem_type = elem[2]
        local rd = rawdata[i]
        local value

        if     elem_type == "number"  then value = tonumber(rd)
        elseif elem_type == "string"  then value = rd
        elseif elem_type == "boolean" then value = (tonumber(rd) == 1)
        else return nil end

        if value == nil then return nil end
        sound_info[elem_name] = value
    end

    return sound_info
end

-- initialize external soundcard
local function _init_ext_sc()
    local false_pos_vol_ctrl = false
    local info = helpmod.sound_info
    local default_volume
    local cmd

    if info.bus_type == t_bus.bluetooth then
        false_pos_vol_ctrl = true
    end

    -- volume can be controlled via SW
    if info.has_vol_ctrl and not false_pos_vol_ctrl then
        default_volume = hcfg.ext_sc_init_val

    -- must be an external soundcard w/ an external volume setting, e.g. an amp
    else
        default_volume = 100
    end

    cmd = _fill_args(hcmd.s_volume, { default_volume })
    helpmod.sound_info.volume = default_volume
    awful.spawn(cmd)
end

local function _update_sound_info(command_output)
    local sinfo

    sinfo = _parse_sound_info(command_output)
    if not sinfo then return false end

    -- force uppercase bus type
    sinfo.bus_type = string.upper(sinfo.bus_type)
    -- some PCI sound devices report no volume setting cap. falsely
    if sinfo.bus_type == t_bus.pci then
        sinfo.has_vol_ctrl = true
    end

    helpmod.sound_info = sinfo

    return true
end


local function _update_volume_box(cmd)
    local box = helpmod.widgets.volume.box
    cmd = cmd or hcmd.g_soundinfo

    if not box then return end

    awful.spawn.easy_async(cmd, function(stdout, stderr, _, exit_code)
        --debug_print_perm("cmd='"..cmd.."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        local is_ext_sc
        local prev_bus
        local text
        local bus
        local vol
        local ret

        if exit_code ~= 0 then
            -- flock couldn't acquire lock, just drop
            if exit_code == 9 then return end
            box.markup = "no sound"
            return
        end

        prev_bus = helpmod.sound_info.bus_type

        ret = _update_sound_info(_remove_newline(stdout))
        if not ret then box.markup = "no sound" return end

        bus = helpmod.sound_info.bus_type
        is_ext_sc = (bus ~= t_bus.pci)
        vol = helpmod.sound_info.volume

        -- check for bus type change and do setup
        if is_ext_sc and bus ~= prev_bus then
            _init_ext_sc()
        end

        -- muted state is common and special
        if helpmod.sound_info.is_muted then
            box.markup = hfnc.add_pango_fg(hcfg.volume_mute_color, hcfg.label_muted..'['..vol..']')
            return
        end

        is_bt_sc = nil
        is_usb_sc = nil

        -- set base label
        if is_ext_sc then
            if bus == t_bus.bluetooth then
                is_bt_sc = true
                text = hcfg.label_bt
            elseif bus == t_bus.usb then
                is_usb_sc = true
                text = hcfg.label_usb
            else
                text = hcfg.label_ext.."-"..string.sub(bus,1,3)
            end
        elseif helpmod.sound_info.jack_plugged then
            text = hcfg.label_jack
        else
            text = hcfg.label_speaker
        end
        text = text .. ":" .. vol

        -- soundcard has volume setting capability, so colorize
        if helpmod.sound_info.has_vol_ctrl then
            if vol >= hcfg.volume_high then
                box.markup = hfnc.add_pango_fg(hcfg.volume_high_color, text)
            elseif vol >= hcfg.volume_mid then
                box.markup = hfnc.add_pango_fg(hcfg.volume_mid_color, text)
            else
                box.markup = text
            end
        -- must be an external soundcard w/ an external volume setting, e.g. an amp or bt
        else
            if is_bt_sc  then
                box.markup = hfnc.add_pango_fg(hcfg.volume_bt_color, text)
            elseif is_usb_sc then
                box.markup = hfnc.add_pango_fg(hcfg.volume_usb_color, text)
            else
                box.markup = hfnc.add_pango_fg(hcfg.volume_ext_color, text)
            end
        end
    end)
end

local function _modify_volume(new_volume)
    local cmd = _fill_args(hcmd.sg_volume, { new_volume })
    _update_volume_box(cmd)
end

local function _modify_volume_rel(increase)
    local vol

    if increase then vol = "+" else vol = "-" end

    if helpmod.sound_info.has_vol_ctrl then
        vol = vol .. tostring(hcfg.vol_step)
    else
        vol = vol .. tostring(hcfg.ext_step)
    end

    _modify_volume(vol)
end

local function __update_mpstate_box(state, boxes, images)
    if state ~= _prev_states.mp then
        if state == "Playing" then
            boxes[1].image = images["pause"]
        else
            boxes[1].image = images["play"]
        end
        _prev_states.mp = state
    end

    for i = 1, #boxes do
        if not boxes[i].visible then boxes[i].visible = true end
    end
end

local function _update_mpstate_box()
    local images = helpmod.widgets.mpstate.images
    local boxes = helpmod.widgets.mpstate.boxes
    local cmd = hcmd.g_mpstatus

    if not (boxes and images) then return end

    awful.spawn.easy_async(cmd, function(stdout, stderr, _, exit_code)
        --debug_print_perm("cmd='"..cmd.."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        local state

        if exit_code ~= 0 then
            for i = 1, #boxes do
                if boxes[i].visible then boxes[i].visible = false end
            end
            return
        end

        state = _remove_newline(stdout)
        __update_mpstate_box(state, boxes, images)
    end)
end

local function _update_backlight_box(cmd)
    local box = helpmod.widgets.backlight.box
    cmd = cmd or hcmd.g_backlight

    if not box then return end

    awful.spawn.easy_async(cmd, function(stdout, stderr, _, exit_code)
        --debug_print_perm("cmd='"..cmd.."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        local label = 'backlight: '

        if exit_code ~= 0 then
            box.markup = "<error>"
            return
        end

        if not box.visible then box.visible = true end

        box.markup = hcfg.separ_txt..label..
            hfnc.add_pango_fg(hcfg.warn_color, math.floor(tonumber(stdout)))
    end)
end

local function _update_battery_box()
    local timer = helpmod.widgets.battery.timer
    local box = helpmod.widgets.battery.box
    local cmd = hcmd.g_battery

    if not (box and timer) then return end

    awful.spawn.easy_async(cmd, function(stdout, stderr, _, exit_code)
        --debug_print_perm("cmd='"..cmd.."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)
        local cap = tonumber(stdout)
        local text = 'B:'..cap
        local battery_status
        local ac

        if exit_code ~= 0 then
            --debug_print("BB_stderr="..stderr)
            box.markup = "no battery"
            if timer.started then timer:stop() end
            return
        end

        ac = helpmod.get_ac_status()
        battery_status = helpmod.get_battery_status()

        if battery_status == "Charging" then
            box.markup = hfnc.add_pango_fg(hcfg.battery_charge_color, text)
        elseif ac == 1 then
            box.markup = hfnc.add_pango_fg(hcfg.ac_plugged_color, text)
        elseif cap <= hcfg.battery_low then
                box.markup = hfnc.add_pango_fg(hcfg.battery_low_color, text)
                if cap < _prev_states.bat and math.fmod(cap, hcfg.battery_low_notif_gap) == 0 then
                    _prev_states.bat = cap
                    warn_print("low battery: "..cap.."%")
                end
        else
            box.markup = text
        end
    end)
end

local function _update_fanspeed_box(cmd)
    local box = helpmod.widgets.fanspeed.box

    if not box then return end
    if not cmd then return end

    awful.spawn.easy_async(cmd, function(stdout, stderr, _, exit_code)
        --debug_print_perm("cmd='"..cmd.."'\nstdout='"..stdout.."'\nstderr='"..stderr.."'\nexit="..exit_code)

        if exit_code ~= 0 then
            box.markup = "<error>"
            return
        end

        box.markup = _remove_newline(stdout).." RPM"
    end)
end
-- }}}

function helpmod.lower_volume()
    if helpmod.sound_info.volume <= 0 then return end
    _modify_volume_rel(false)
end

function helpmod.raise_volume()
    if helpmod.sound_info.volume >= hcfg.volume_max then return end
    _modify_volume_rel(true)
end

function helpmod.toggle_mute()
    _update_volume_box(hcmd.sg_togglemute)
end

function helpmod.toggle_slight_volume()
    local slightvol = hcfg.volume_slight
    local prevvol = _prev_states.vol

    -- do not switch to a prev. value if it's been set to 5 since then
    _prev_states.vol = helpmod.sound_info.volume
    if helpmod.sound_info.volume == slightvol then
        _modify_volume(prevvol)
    else
        _modify_volume(slightvol)
    end
end

function helpmod.update_volume_box()
    _update_volume_box()
end

function helpmod.update_mpstate_box(data)
    if data then
        local images = helpmod.widgets.mpstate.images
        local boxes = helpmod.widgets.mpstate.boxes
        if not (boxes and images) then return end

        __update_mpstate_box(data, boxes, images)
    else
        _update_mpstate_box()
    end
end

function helpmod.brightness_down()
    local cmd = _fill_args(hcmd.sg_brightdown, { hcfg.bl_step })
    _update_backlight_box(cmd)
end

function helpmod.brightness_up()
    local cmd = _fill_args(hcmd.sg_brightup, { hcfg.bl_step })
    _update_backlight_box(cmd)
end

function helpmod.update_backlight_box()
    _update_backlight_box()
end

function helpmod.update_battery_box()
    _update_battery_box()
end

function helpmod.update_fanspeed_box(hwmon_dev_num)
    local cmd = _fill_args(hcmd.g_fanspeed, {hwmon_dev_num})
    _update_fanspeed_box(cmd)
end

function helpmod.get_network_stats(_, args, netdevs)
    local dec_places = hcfg.nw_decimal_places
    local down_label = "Rx"
    local down_unit = "K"
    local up_label = "Tx"
    local up_unit = "K"
    local kilo = 1024
    local text = ""

    for i = 1, #netdevs do
        local nwdev = netdevs[i]
        if args["{"..nwdev.." carrier}"] == 1 then
            local down_val = tonumber(args['{'..nwdev..' down_b}']) / kilo
            local up_val = tonumber(args['{'..nwdev..' up_b}']) / kilo
            local dev_label = nwdev..': '
            local down_str
            local up_str

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

            -- add color to tunnels
            if string.match(nwdev, "tun") then
                dev_label = hfnc.add_pango_fg(hcfg.net_tunnel_color, dev_label)
            end
            text = text..' - '..dev_label
                        ..hfnc.add_pango_fg(hcfg.net_download_color, down_label..' '..down_str)
                        ..' / '
                        ..hfnc.add_pango_fg(hcfg.net_upload_color, up_label..' '..up_str)
      end
    end

    -- remove separator
    if string.len(text) > 0 then
        return string.sub(text, 4, -1)
    end

    return 'no network'
end

function helpmod.get_coretemp_text(temp, data)
    -- data can be either core index or full label string
    local label = tonumber(data) and 'core ' .. data .. ': ' or data
    local text = temp..'°C'

    if temp <= hcfg.cpu_temp_mid then
        label = label..hfnc.add_pango_fg(hcfg.cpu_temp_low_color, text)
    elseif temp <= hcfg.cpu_temp_high  then
        label = label..hfnc.add_pango_fg(hcfg.cpu_temp_medium_color, text)
    else
        label = label..hfnc.add_pango_fg(hcfg.cpu_temp_high_color, text)
    end

    -- should include separator
    return label..hcfg.separ_txt
end

-- The following functions are either called once at startup,
-- and/or on events, and/or in callbacks, so popen is ok

function helpmod.is_on_laptop()
    local h = assert(io.popen(hcmd.g_onlaptop))
    local ret = h:read("*n")
    h:close()
    return ret == 0
end

function helpmod.get_cpu_core_count()
    local h = assert(io.popen(hcmd.g_corecnt))
    local num = h:read("*n")
    h:close()
    return num
end

function helpmod.get_net_devices()
    local excludes = { "lo[0-9]*", "docker[0-9]*", "bond[0-9]*", "veth*" }
    local h = assert(io.popen(hcmd.g_netdevs))
    local ret = h:read("*a")
    h:close()
    return hfnc.str_to_table(ret, "%s", excludes)
end

function helpmod.get_product()
    local h = assert(io.popen(hcmd.g_product))
    local ret = h:read("*a")
    h:close()
    return ret
end

function helpmod.get_hwmon_num(hwmon_name)
    local cmd = _fill_args(hcmd.g_hwmon, { hwmon_name })
    local h = assert(io.popen(cmd))
    local ret = h:read("*n")
    h:close()
    return ret
end

function helpmod.get_battery_status()
    local h = assert(io.popen(hcmd.g_bat_stat))
    local ret = h:read("*a")
    h:close()
    return ret
end

function helpmod.get_ac_status()
    local h = assert(io.popen(hcmd.g_aconline))
    local ret = h:read("*n")
    h:close()
    return ret
end

function helpmod.init_sound()
    local h = assert(io.popen(hcmd.g_soundinfo))
    local ret = h:read("*a")

    h:close()

    ret = _update_sound_info(_remove_newline(ret))
    if not ret then return end

    -- init external devices
    if helpmod.sound_info.bus_type ~= t_bus.pci then
        _init_ext_sc()
    end

    return
end

return helpmod

-- vim: autoindent tabstop=8 shiftwidth=4 expandtab softtabstop=4 filetype=lua
