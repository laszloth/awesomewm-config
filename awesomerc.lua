-- awesome_mode: api-level=4:screen=on
-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- @DOC_REQUIRE_SECTION@
-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
-- Declarative object management
local ruled = require("ruled")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
-- Enable hotkeys help widget for VIM and other apps
-- when client with a matching name is opened:
require("awful.hotkeys_popup.keys")

local vicious = require("vicious")
-- C API
local capi = { awesome = awesome }
-- own helpmod
local helpmod = require("helpmod.helpmod")
local hcfg = helpmod.cfg
local hcmd = helpmod.cmd
local hfnc = helpmod.fnc
-- button helpers
local left_mb     = 1
--local middle_mb   = 2
local right_mb    = 3
local scroll_up   = 4
local scroll_down = 5
-- extra tag
local hiddentag
-- tag configuration
local tags_cfg = {
    names = { "null", "head", "main", "www", "term", "enigm", "myst", "kreat", "riddler" },
    layouts = {
           awful.layout.layouts[2], -- null
           awful.layout.layouts[3], -- head
           awful.layout.layouts[2], -- main
           awful.layout.layouts[3], -- www
           awful.layout.layouts[2], -- term
           awful.layout.layouts[2], -- enigm
           awful.layout.layouts[2], -- myst
           awful.layout.layouts[3], -- kreat
           awful.layout.layouts[1], -- riddler
    },
}

-- {{{ Debug functions
function debug_print(message, timeout)
    naughty.notify({ preset = naughty.config.presets.critical,
        timeout = timeout or 5,
        title = "DEBUG MESSAGE",
        text = tostring(message) })
end

function debug_print_perm(message, screen)
    naughty.notify({ preset = naughty.config.presets.critical,
        screen = screen or def_screen,
        title = "DEBUG MESSAGE",
        text = tostring(message) })
end
-- }}} Debug functions

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
-- @DOC_ERROR_HANDLING@
naughty.connect_signal("request::display_error", function(message, startup)
    naughty.notification {
        urgency = "critical",
        title   = "Oops, an error happened"..(startup and " during startup!" or "!"),
        message = message
    }
end)
-- }}}

-- Get config dir and start autorun script
local config_dir = gears.filesystem.get_configuration_dir()
awful.spawn.with_shell(config_dir .. "scripts/autorun.sh &>/dev/null")

-- {{{ Variable definitions
-- @DOC_LOAD_THEME@
-- Themes define colours, icons, font and wallpapers.
beautiful.init(config_dir .. "theme/theme.lua")

-- @DOC_DEFAULT_APPLICATIONS@
-- This is used later as the default terminal and editor to run.
terminal    = hcmd.terminal
editor      = os.getenv("EDITOR") or hcmd.editor
editor_cmd  = terminal .. " -e " .. editor

-- Various variables
local cpu_cores = helpmod.get_cpu_core_count()
local net_devs = helpmod.get_net_devices()
local on_laptop = helpmod.is_on_laptop()
local product = helpmod.get_product()
local cput_widgets = {}
local num_screen = 1
local def_screen = num_screen

-- Product specific variables
local cputemp_hwmon_device_num
local fanspeed_hwmon_device_num

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- {{{ Helper functions
local function warn_print(message, timeout)
    naughty.notify({ preset = naughty.config.presets.critical,
        timeout = timeout or 10,
        title = "warning",
        text = tostring(message) })
end

local function update_screen_count()
    num_screen = screen.count()
    def_screen = math.floor(num_screen / 3) + 1
    --debug_print_perm("screen count="..num_screen .. ", default screen=" .. def_screen)
end

local function rename_current_tag()
    awful.prompt.run {
        prompt       = ' Tag name: ',
        textbox      = mouse.screen.mypromptbox.widget,
        exe_callback = function(name)
            if not name or #name == 0 then return end

            local ctag = mouse.screen.selected_tag
            if ctag then
                ctag.name = name
            end
        end
    }
end

local function reset_all_tags()
    for s in screen do
        for i = 1, #tags_cfg.names do
            local tag = s.tags[i]
            local orig_name = tags_cfg.names[i]
            if tag and tag.name ~= orig_name
            then
                tag.name = orig_name
            end
        end
    end
end
-- }}}

---------------------------------
-- all vars and helpers set up --
---------------------------------

-- Default screen settings for Firefox and others
update_screen_count()

-- Product specific setup
if hfnc.string_contains(product, 'OptiPlex 7050') then
    cputemp_hwmon_device_num = helpmod.get_hwmon_num('coretemp')
    fanspeed_hwmon_device_num = helpmod.get_hwmon_num('dell_smm')
elseif hfnc.string_contains(product, 'ThinkPad X280') then
    cputemp_hwmon_device_num = helpmod.get_hwmon_num('coretemp')
    fanspeed_hwmon_device_num = helpmod.get_hwmon_num('thinkpad')
elseif hfnc.string_contains(product, 'Precision 5820') then
    cputemp_hwmon_device_num = helpmod.get_hwmon_num('coretemp')
    fanspeed_hwmon_device_num = helpmod.get_hwmon_num('dell_smm')
    if num_screen > 1 then screen[2]:swap(screen[3]) end
else
    debug_print("Not implemented product name: '" .. product .. "'." )
    cputemp_hwmon_device_num = 0
    fanspeed_hwmon_device_num = 0
end

-- {{{ Menu
-- @DOC_MENU@
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end },
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Tag
-- @DOC_LAYOUT@
-- Table of layouts to cover with awful.layout.inc, order matters.
tag.connect_signal("request::default_layouts", function()
    awful.layout.append_default_layouts({
        awful.layout.suit.floating,
        awful.layout.suit.tile,
        awful.layout.suit.max,
        awful.layout.suit.max.fullscreen,
        awful.layout.suit.corner.nw,
        awful.layout.suit.magnifier,
    --    awful.layout.suit.tile.left,
    --    awful.layout.suit.tile.bottom,
    --    awful.layout.suit.tile.top,
    --    awful.layout.suit.fair,
    --    awful.layout.suit.fair.horizontal,
    --    awful.layout.suit.spiral,
    --    awful.layout.suit.spiral.dwindle,
    --    awful.layout.suit.corner.nw,
    })
end)
-- }}}

-- {{{ Wibar

-- Keyboard map indicator and switcher
--mykeyboardlayout = awful.widget.keyboardlayout()

-- Create a textclock widget
mytextclock = wibox.widget.textclock("%Y-%m-%d %a %H:%M:%S", 1)

-- Create music player state indicator
local mpspace = wibox.widget.textbox()
mpspace.text = hcfg.space_txt
local mympstate = wibox.widget.imagebox(beautiful.paused, true)
mympstate.forced_width = 14
mympstate.opacity = 0.8

local myplacedmpstate = wibox.container.place(mympstate)
myplacedmpstate:buttons(gears.table.join(
                     awful.button({ }, left_mb, function () awful.spawn(hcmd.s_playtoggle) end),
--                     awful.button({ }, right_mb, function () awful.spawn(hcmd.s_playtoggle) end),
                     awful.button({ }, scroll_up, function () awful.spawn(hcmd.s_next) end),
                     awful.button({ }, scroll_down, function () awful.spawn(hcmd.s_prev) end)))

helpmod.widgets["mpstate"] = {
    boxes = { mympstate, mpspace },
    images = { play = beautiful.play, pause = beautiful.pause }
}
helpmod.update_mpstate_box()

-- Create systray and its separator
local mystseparator = wibox.widget.textbox()
mystseparator.text = hcfg.separ_txt
local mysystray = wibox.widget.systray()
local function check_systray()
    local entries = capi.awesome.systray()
    --debug_print("systray entries="..entries)
    if entries == 0 then
        mystseparator.visible = false
    else
        mystseparator.visible = true
    end
end
mysystray:connect_signal("widget::redraw_needed", check_systray)
check_systray()

-- Create backlight widget
local myblwidget = nil
local mybltimer = nil
if on_laptop then
    myblwidget = wibox.widget.textbox()
    helpmod.widgets["backlight"] = { box = myblwidget }
    helpmod.update_backlight_box()

    -- timer to hide backlight textbox
    mybltimer = gears.timer { timeout = hcfg.backlight_timeout, }
    mybltimer:connect_signal("timeout", function()
        --debug_print_perm("mybltimer expired")
        myblwidget.visible = false
        mybltimer:stop() end)
    mybltimer:start()
end

-- Create volume widget
local myvolwidget = wibox.widget.textbox()
myvolwidget.markup = 'n/a'

myvolwidget:buttons(gears.table.join(
                     awful.button({ }, left_mb, function () helpmod.toggle_mute() end),
                     awful.button({ }, right_mb, function () helpmod.toggle_slight_volume() end),
                     awful.button({ }, scroll_up, function () helpmod.raise_volume() end),
                     awful.button({ }, scroll_down, function () helpmod.lower_volume() end)))

helpmod.widgets["volume"] = { box = myvolwidget }
helpmod.update_volume_box()

-- Create battery widget
local mybatwidget
local mybattimer
if on_laptop then
    mybatwidget = wibox.widget.textbox()
    mybattimer = gears.timer { timeout = hcfg.battery_timeout, }
    mybattimer:connect_signal("timeout", function()
        --debug_print_perm("mybattimer expired")
        helpmod.update_battery_box()
    end)

    helpmod.widgets["battery"] = { box = mybatwidget, timer = mybattimer}
    helpmod.update_battery_box()
    mybattimer:start()
end

-- Create net widget
local mynetwidget = wibox.widget.textbox()
vicious.register(mynetwidget, vicious.widgets.net, function(widget, args)
    return helpmod.get_network_stats(widget, args, net_devs)
end, 1)

-- Create CPU widgets

-- CPU: fanspeed
local mycpufanwidget = nil
local mycpufantimer = nil
mycpufanwidget = wibox.widget.textbox()
helpmod.widgets["fanspeed"] = { box = mycpufanwidget }
helpmod.update_fanspeed_box(fanspeed_hwmon_device_num)

mycpufantimer = gears.timer { timeout = 5 }
mycpufantimer:connect_signal("timeout", function()
    helpmod.update_fanspeed_box(fanspeed_hwmon_device_num)
end)
mycpufantimer:start()

-- CPU: thermal
local mycpupkgtempwidget = wibox.widget.textbox()
vicious.register(mycpupkgtempwidget, vicious.widgets.thermal,
    function(_, args) return helpmod.get_coretemp_text(args[1], 'pkg: ') end,
    1, { 'hwmon'..cputemp_hwmon_device_num, 'hwmon', 'temp1_input' })

local mycputempwidget = wibox.layout.fixed.horizontal()

for i = 2, 1 + cpu_cores do
    local c = wibox.widget.textbox()
    c:connect_signal("button::release", function()
        local s = mouse.screen.index
        cput_widgets[s].visible = not cput_widgets[s].visible
    end)
    vicious.register(c, vicious.widgets.thermal,
        function(_, args) return helpmod.get_coretemp_text(args[1], i - 2) end,
        1, { 'hwmon'..cputemp_hwmon_device_num, 'hwmon', 'temp'..i..'_input' })
    mycputempwidget:add(c)
end

-- CPU: frequency
local mycpufreqwidget = wibox.widget.textbox()
vicious.register(mycpufreqwidget, vicious.widgets.cpufreq,
    function(_, args) return math.floor(args[1]).." MHz" end,
    hcfg.cpu_freq_refresh_time, "cpu0")

-- CPU: usage
local myusagewidget = wibox.widget.textbox()
vicious.register(myusagewidget, vicious.widgets.cpu, function(_, args)
    return string.format("%02d", args[1]).."%" end, 1)
myusagewidget:connect_signal("button::release", function()
    local s = mouse.screen.index
    cput_widgets[s].visible = not cput_widgets[s].visible
end)

-- external events via "awesome-client"
function ext_event_handler(event, data)
    --debug_print("Received event: "..event)
    if event == "acpi_jack" then
        awful.spawn(hcmd.s_pause)
        helpmod.update_volume_box()
    elseif event == "acpi_ac" and on_laptop then
        helpmod.update_battery_box()
    elseif event == "mp_stat" then
        helpmod.update_mpstate_box(data)
    elseif event == "mp_quit" then
        mympstate.visible = false
        mpspace.visible = false
    elseif event == "net" then
        net_devs = helpmod.get_net_devices()
    else
        event = event or "nil"
        debug_print_perm('Wrong event string: "'..event..'"')
    end
end

-- @DOC_WALLPAPER@
screen.connect_signal("request::wallpaper", function(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end)

-- @DOC_FOR_EACH_SCREEN@
screen.connect_signal("request::desktop_decoration", function(s)
    local first_screen = (s.index == 1)

    --debug_print_perm("Screen #"..s.index, s.index)

    -- connect to signals
    if first_screen then
        s:connect_signal("removed", function()
            debug_print("a screen has been removed", 10)
            update_screen_count()
        end)
        s:connect_signal("added", function()
            debug_print("a screen has been added", 10)
            update_screen_count()
        end)
    end

    -- Each screen has its own tag table.
    awful.tag( tags_cfg.names, s, tags_cfg.layouts )

    -- create a last, hidden tag on the first screen
    if first_screen then
        hiddentag = awful.tag({ "hidden" }, s, awful.layout.layouts[1])
        awful.tag.setproperty(hiddentag[1], "hide", true)
    end

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt {
        prompt = ' Execute: ',
        bg = beautiful.prompt_bg,
        fg = beautiful.prompt_fg
    }

    -- Create an imagebox widget which will contain an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox {
        screen  = s,
        buttons = {
            awful.button({ }, 1, function () awful.layout.inc( 1) end),
            awful.button({ }, 3, function () awful.layout.inc(-1) end),
            awful.button({ }, 4, function () awful.layout.inc(-1) end),
            awful.button({ }, 5, function () awful.layout.inc( 1) end),
        }
    }

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = {
            awful.button({ }, 1, function(t) t:view_only() end),
            awful.button({ modkey }, 1, function(t)
                                            if client.focus then
                                                client.focus:move_to_tag(t)
                                            end
                                        end),
            awful.button({ }, 3, awful.tag.viewtoggle),
            awful.button({ modkey }, 3, function(t)
                                            if client.focus then
                                                client.focus:toggle_tag(t)
                                            end
                                        end),
            awful.button({ }, 4, function(t) awful.tag.viewprev(t.screen) end),
            awful.button({ }, 5, function(t) awful.tag.viewnext(t.screen) end),
        }
    }

    -- @TASKLIST_BUTTON@
    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = {
            awful.button({ }, 1, function (c)
                c:activate { context = "tasklist", action = "toggle_minimization" }
            end),
            awful.button({ }, 3, function() awful.menu.client_list { theme = { width = 250 } } end),
            awful.button({ }, 4, function() awful.client.focus.byidx(-1) end),
            awful.button({ }, 5, function() awful.client.focus.byidx( 1) end),
        }
    }

    -- @DOC_WIBAR@
    -- Create the wibox
    s.mywibox = awful.wibar({ position = "bottom", height = 22, screen = s })

    -- @DOC_SETUP_WIDGETS@
    -- spaces and separator
    local space1 = wibox.widget.textbox()
    space1.text = hcfg.space_txt
    local separator = wibox.widget.textbox()
    separator.text = hcfg.separ_txt

    -- Add widgets to the wibox
    local leftl = wibox.layout.fixed.horizontal(
            --mylauncher,
            s.mytaglist,
            s.mypromptbox,
            separator)

    local middlel = s.mytasklist
    local rightl = wibox.layout.fixed.horizontal(
            space1,
            myusagewidget,
            separator,
            mycpufreqwidget,
            separator,
            mycpufanwidget,
            separator,
            mycpupkgtempwidget)

    local ctc = wibox.container.background(mycputempwidget)
    cput_widgets[s.index] = ctc
    -- do not fill screen w/ cpu temps by default if core count is high
    if cpu_cores > 12 then ctc.visible = false end
    rightl:add(ctc)

    rightl:add(mynetwidget) rightl:add(separator)
    if first_screen then
        rightl:add(mysystray) rightl:add(mystseparator)
        --rightl:add(mykeyboardlayout) rightl:add(separator)
    end
    rightl:add(myplacedmpstate) rightl:add(mpspace)
    rightl:add(myvolwidget)
    -- separator included
    if on_laptop and first_screen then rightl:add(myblwidget) end

    rightl:add(separator)
    if on_laptop then rightl:add(mybatwidget) rightl:add(separator) end
    rightl:add(mytextclock) rightl:add(space1)
    rightl:add(s.mylayoutbox)

    s.mywibox:setup {
        leftl,
        middlel,
        rightl,
        layout = wibox.layout.align.horizontal,
    }
end)
-- }}}

-- {{{ Mouse bindings
-- @DOC_ROOT_BUTTONS@
awful.mouse.append_global_mousebindings({
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewprev),
    awful.button({ }, 5, awful.tag.viewnext),
})
-- }}}

-- {{{ Key bindings
-- @DOC_GLOBAL_KEYBINDINGS@

-- General Awesome keys
awful.keyboard.append_global_keybindings({
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                    prompt       = "Run Lua code: ",
                    textbox      = awful.screen.focused().mypromptbox.widget,
                    exe_callback = awful.util.eval,
                    history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end,
              {description = "lua execute prompt", group = "awesome"}),
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"}),
})

-- Tags related keybindings
awful.keyboard.append_global_keybindings({
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),
})

-- Focus related keybindings
awful.keyboard.append_global_keybindings({
    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
        end,
        {description = "focus next by index", group = "client"}
    ),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
        end,
        {description = "focus previous by index", group = "client"}
    ),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                    c:activate { raise = true, context = "key.unminimize" }
                  end
              end,
              {description = "restore minimized", group = "client"}),
})

-- Layout related keybindings
awful.keyboard.append_global_keybindings({
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end,
              {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end,
              {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end,
              {description = "increase the number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end,
              {description = "decrease the number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end,
              {description = "increase the number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end,
              {description = "decrease the number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end,
              {description = "select next", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end,
              {description = "select previous", group = "layout"}),
})

-- @DOC_NUMBER_KEYBINDINGS@
local keycodes = {49, 10, 11, 12, 13, 14, 15, 16, 17, 18}
for index, kcode in pairs(keycodes)  do
    awful.keyboard.append_global_keybindings({
        -- View tag only.
        awful.key({ modkey }, "#" .. kcode,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[index]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "only view tag", group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. kcode,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[index]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag", group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. kcode,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[index]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag", group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. kcode,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[index]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag", group = "tag"})
    })
end

-- My keybindings
awful.keyboard.append_global_keybindings({
    -- Rename current tag
    awful.key({ modkey, "Shift" },   "t", function () rename_current_tag() end,
              {description = "rename current tag", group = "awesome"}),

    -- Reset all tags
    awful.key({ modkey, "Control" }, "t", function () reset_all_tags() end,
              {description = "reset tags", group = "awesome"}),

    -- Assign special keys
    awful.key({ "Control", "Mod1" }, "Delete", function()
        awful.spawn(hcmd.locker) end),
    awful.key({ }, "XF86AudioLowerVolume", function()
        helpmod.lower_volume() end),
    awful.key({ }, "XF86AudioRaiseVolume", function()
        helpmod.raise_volume() end),
    awful.key({ }, "XF86AudioMute", function()
        helpmod.toggle_mute() end),
    awful.key({ }, "XF86AudioNext", function()
        awful.spawn(hcmd.s_next)
        end),
    awful.key({ }, "XF86AudioPrev", function()
        awful.spawn(hcmd.s_prev)
        end),
    awful.key({ }, "XF86AudioPlay", function()
        awful.spawn(hcmd.s_playtoggle)
        end),
    awful.key({ }, "XF86Calculator", function()
        awful.spawn(hcmd.calculator) end),
    awful.key({ }, "XF86TouchpadToggle", function()
        if on_laptop then
            awful.spawn(hcmd.s_toggletp)
        end end),
    -- in case of no dedicated button present
    awful.key({ modkey }, "F5",  function()
        if on_laptop then
            awful.spawn(hcmd.s_toggletp)
        end end),
    awful.key({ }, "XF86MonBrightnessDown", function()
        if on_laptop then
            helpmod.brightness_down()
            mybltimer:again()
        end end),
    awful.key({ }, "XF86MonBrightnessUp", function()
        if on_laptop then
            helpmod.brightness_up()
            mybltimer:again()
        end end),
})

-- @DOC_CLIENT_BUTTONS@
client.connect_signal("request::default_mousebindings", function()
    awful.mouse.append_client_mousebindings({
        awful.button({ }, 1, function (c)
            c:activate { context = "mouse_click" }
        end),
        awful.button({ modkey }, 1, function (c)
            c:activate { context = "mouse_click", action = "mouse_move"  }
        end),
        awful.button({ modkey }, 3, function (c)
            c:activate { context = "mouse_click", action = "mouse_resize"}
        end),
    })
end)

-- @DOC_CLIENT_KEYBINDINGS@
client.connect_signal("request::default_keybindings", function()
    awful.keyboard.append_client_keybindings({
        awful.key({ modkey,           }, "f",
            function (c)
                c.fullscreen = not c.fullscreen
                c:raise()
            end,
            {description = "toggle fullscreen", group = "client"}),
        awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end,
                {description = "close", group = "client"}),
        awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ,
                {description = "toggle floating", group = "client"}),
        awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
                {description = "move to master", group = "client"}),
        awful.key({ modkey,           }, "o",      function (c) c:move_to_screen(c.screen.index+1) end,
                {description = "move to next screen", group = "client"}),
        awful.key({ modkey, "Shift"   }, "o",      function (c) c:move_to_screen(c.screen.index-1) end,
                {description = "move to prev. screen", group = "client"}),
        awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end,
                {description = "toggle keep on top", group = "client"}),
        awful.key({ modkey,           }, "n",
            function (c)
                -- The client currently has the input focus, so it cannot be
                -- minimized, since minimized clients can't have the focus.
                c.minimized = true
            end ,
            {description = "minimize", group = "client"}),
        awful.key({ modkey,           }, "m",
            function (c)
                c.maximized = not c.maximized
                c:raise()
            end ,
            {description = "(un)maximize", group = "client"}),
        awful.key({ modkey, "Control" }, "m",
            function (c)
                c.maximized_vertical = not c.maximized_vertical
                c:raise()
            end ,
            {description = "(un)maximize vertically", group = "client"}),
        awful.key({ modkey, "Shift"   }, "m",
            function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c:raise()
            end ,
            {description = "(un)maximize horizontally", group = "client"}),
    })
end)

-- {{{ Rules
-- Rules to apply to new clients.
-- @DOC_RULES@
ruled.client.connect_signal("request::rules", function()
    -- @DOC_GLOBAL_RULE@
    -- All clients will match this rule.
    ruled.client.append_rule {
        id         = "global",
        rule       = { },
        properties = {
            focus     = awful.client.focus.filter,
            raise     = true,
            screen    = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen
        }
    }

    -- @DOC_FLOATING_RULE@
    -- Floating clients.
    ruled.client.append_rule {
        id       = "floating",
        rule_any = {
            instance = { "copyq", "pinentry" },
            class    = {
                "Arandr", "Blueman-manager", "Gpick", "Kruler", "Sxiv",
                "Tor Browser", "Wpa_gui", "veromix", "xtightvncviewer"
            },
            -- Note that the name property shown in xprop might be set slightly after creation of the client
            -- and the name shown there might not match defined rules here.
            name    = {
                "Event Tester",  -- xev.
            },
            role    = {
                "AlarmWindow",    -- Thunderbird's calendar.
                "ConfigManager",  -- Thunderbird's about:config.
                "pop-up",         -- e.g. Google Chrome's (detached) Developer Tools.
            }
        },
        properties = { floating = true }
    }

    -- @DOC_DIALOG_RULE@
    -- Add titlebars to normal clients and dialogs
    ruled.client.append_rule {
        -- @DOC_CSD_TITLEBARS@
        id         = "titlebars",
        rule_any   = { type = { "normal", "dialog" } },
        properties = { titlebars_enabled = hcfg.titlebars_enabled }
    }

    -- Set Conky to be on a hidden tag without centering
    ruled.client.append_rule {
        rule = { class = "Conky" },
        properties = { placement = awful.placement.no_offscreen,
                     tag = hiddentag[1] }
     }

    -- Set Firefox to always map on www tag on last screen
    ruled.client.append_rule {
        rule = { class = "firefox" },
        properties = { screen = num_screen, tag = "www" }
     }

    -- Set Chrome to always map on www tag on first screen
    ruled.client.append_rule {
        rule = { class = "Google-chrome" },
        properties = { screen = 1, tag = "www" }
     }

    -- Set Evolution to always map to first tag on first screen
    ruled.client.append_rule {
        rule = { class = "Evolution" },
        properties = { screen = 1, tag = "head" }
     }

    -- Set Pidgin to always map to first tag and be br. floating on first screen
    ruled.client.append_rule {
        rule = { class = "Pidgin" },
        properties = { screen = 1, tag = "head",
                     floating = true,
                     placement = awful.placement.bottom_right }
     }

    -- Set gnome-calculator to always be floating
    ruled.client.append_rule {
        rule_any = { class = { "Gnome-calculator", "gnome-calculator" } },
        properties = { floating = true }
     }

    -- Set Spotify to always map to 'kreat' tag on last screen, maximized
    ruled.client.append_rule {
        rule = { class = "Spotify" },
        properties = { screen = num_screen, tag = "kreat",
                     maximized = true }
     }

    -- Set Steam to always map to 'main' tag on first screen, maximized
    ruled.client.append_rule {
        rule = { class = "Steam" },
        properties = { screen = 1, tag = "main",
                     maximized = true }
     }

    -- Set konsole to start unmaximized at the center
    ruled.client.append_rule {
        rule = { class = "konsole" },
        properties = { maximized = false,
                     placement = awful.placement.centered }
     }

    -- Set qjackctl to always be floating
    ruled.client.append_rule {
        rule = { class = "qjackctl" },
        properties = { floating = true,
                     placement = awful.placement.bottom_right }
     }

    -- Set VirtualBox's manager to always be floating
    ruled.client.append_rule {
        rule = { class = "VirtualBox Manager" },
        properties = { floating = true,
                     placement = awful.placement.centered }
     }

    -- Set KeePass to always be floating
    ruled.client.append_rule {
        rule = { class = "KeePass2" },
        properties = { floating = true,
                     placement = awful.placement.centered }
     }

    -- Set gcr prompter to always map to 'head' tag on first screen, floating
    ruled.client.append_rule {
        rule = { class = "Gcr-prompter" },
        properties = { screen = 1, tag = "head",
                     floating = true,
                     placement = awful.placement.centered }
     }
end)
-- }}}

-- {{{ Titlebars
-- @DOC_TITLEBARS@
-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = {
        awful.button({ }, 1, function()
            c:activate { context = "titlebar", action = "mouse_move"  }
        end),
        awful.button({ }, 3, function()
            c:activate { context = "titlebar", action = "mouse_resize"}
        end),
    }

    awful.titlebar(c).widget = {
        { -- Left
            awful.titlebar.widget.iconwidget(c),
            buttons = buttons,
            layout  = wibox.layout.fixed.horizontal
        },
        { -- Middle
            { -- Title
                align  = "center",
                widget = awful.titlebar.widget.titlewidget(c)
            },
            buttons = buttons,
            layout  = wibox.layout.flex.horizontal
        },
        { -- Right
            awful.titlebar.widget.floatingbutton (c),
            awful.titlebar.widget.maximizedbutton(c),
            awful.titlebar.widget.stickybutton   (c),
            awful.titlebar.widget.ontopbutton    (c),
            awful.titlebar.widget.closebutton    (c),
            layout = wibox.layout.fixed.horizontal()
        },
        layout = wibox.layout.align.horizontal
    }
end)

-- {{{ Notifications

ruled.notification.connect_signal('request::rules', function()
    -- All notifications will match this rule.
    ruled.notification.append_rule {
        rule       = { },
        properties = {
            screen           = awful.screen.preferred,
            implicit_timeout = 5,
        }
    }
end)

naughty.connect_signal("request::display", function(n)
    naughty.layout.box { notification = n }
end)

-- }}}

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:activate { context = "mouse_enter", raise = false }
end)

-- set unfocused to a little bit transparent
client.connect_signal("focus", function(c)
                                 c.border_color = beautiful.border_focus
                                 c.opacity = 1
                               end)
client.connect_signal("unfocus", function(c)
                                   c.border_color = beautiful.border_normal
                                   c.opacity = 0.96
                                 end)

-- vim: autoindent tabstop=8 shiftwidth=4 expandtab softtabstop=4 filetype=lua
