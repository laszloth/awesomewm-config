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
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget
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

-- Override awesome.quit when we're using GNOME
_awesome_quit = awesome.quit
awesome.quit = function()
    if os.getenv("XDG_CURRENT_DESKTOP") == "Awesome GNOME" then
       --os.execute("/usr/bin/gnome-session-quit")
       os.execute("pkill -9 gnome-session")
    else
    _awesome_quit()
    end
end

-- {{{ Error handling
-- @DOC_ERROR_HANDLING@
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
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
local cput_widgets = {}
local num_screen = 1
local def_screen = 1

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- @DOC_LAYOUT@
-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
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
--    awful.layout.suit.corner.ne,
--    awful.layout.suit.corner.sw,
--    awful.layout.suit.corner.se,
}

local tags_cfg = {
    names = { "null", "head", "main", "www", "term", "enigm", "myst", "kreat", "riddler" },
    layouts = {
           awful.layout.layouts[3], -- null
           awful.layout.layouts[3], -- head
           awful.layout.layouts[3], -- main
           awful.layout.layouts[3], -- www
           awful.layout.layouts[2], -- term
           awful.layout.layouts[2], -- enigm
           awful.layout.layouts[2], -- myst
           awful.layout.layouts[3], -- kreat
           awful.layout.layouts[1], -- riddler
    },
}
-- }}}

-- {{{ Helper functions
function debug_print(msg)
    naughty.notify({ preset = naughty.config.presets.critical,
        timeout = 5,
        title = "DEBUG MESSAGE",
        text = tostring(msg) })
end

function debug_print_perm(msg)
    naughty.notify({ preset = naughty.config.presets.critical,
        title = "DEBUG MESSAGE",
        text = tostring(msg) })
end

function warn_print(msg)
    naughty.notify({ preset = naughty.config.presets.critical,
        timeout = 10,
        title = "warning",
        text = tostring(msg) })
end

local function notify_print(msg)
    naughty.notify({ preset = naughty.config.presets.normal,
        title = "notification",
        text = tostring(msg) })
end

local function update_screen_count()
    num_screen = screen.count()
    def_screen = math.floor(num_screen / 3) + 1
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

local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}

---------------------------------
-- all vars and helpers set up --
---------------------------------

-- Default screen settings for Firefox and others
update_screen_count()
-- Initialize sound
helpmod.init_sound()

-- {{{ Menu
-- @DOC_MENU@
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

--mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
--                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
mytextclock = wibox.widget.textclock("%Y-%m-%d %a %H:%M:%S", 1)

-- Create music player state indicator
local mpspace = wibox.widget.textbox()
mpspace.text = hcfg.space_txt
local mympstate = wibox.widget.imagebox(beautiful.paused, true)
mympstate.forced_width = 14
mympstate.opacity = 0.8
local myplacedmpstate = wibox.container.place(mympstate)
myplacedmpstate:connect_signal("button::release", function()
    awful.util.spawn(hcmd.s_playtoggle)
end)

helpmod.widgets["mpstate"] = { boxes = { mympstate, mpspace }, images = { beautiful.playing, beautiful.paused }}
helpmod.fresh_mpstate_box()

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
    helpmod.fresh_backlight_box()

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
myvolwidget:connect_signal("button::release", function()
    helpmod.toggle_mute()
end)

helpmod.widgets["volume"] = { box = myvolwidget }
helpmod.fresh_volume_box()

-- Create battery widget
local mybatwidget = nil
local mybattimer = nil
if on_laptop then
    mybatwidget = wibox.widget.textbox()
    mybattimer = gears.timer { timeout = hcfg.battery_timeout, }
    mybattimer:connect_signal("timeout", function()
        --debug_print_perm("mybattimer expired")
        helpmod.fresh_battery_box()
    end)

    helpmod.widgets["battery"] = { box = mybatwidget, timer = mybattimer}
    helpmod.fresh_battery_box()
    mybattimer:start()
end

-- Create net widget
local mynetwidget = wibox.widget.textbox()
vicious.register(mynetwidget, vicious.widgets.net, function(widget, args)
    return helpmod.get_network_stats(widget, args, net_devs)
end, 1)

-- Create CPU widgets

-- CPU: thermal
local mycputempwidget = wibox.layout.fixed.horizontal()
for i = 2, 1 + cpu_cores do
    local c = wibox.widget.textbox()
    c:connect_signal("button::release", function()
        local s = mouse.screen.index
        cput_widgets[s].visible = not cput_widgets[s].visible
    end)
    vicious.register(c, vicious.widgets.thermal,
        function(widget, args) return helpmod.get_coretemp_text(args[1], i) end,
        1, { 'hwmon1', 'hwmon', 'temp'..i..'_input' })

    mycputempwidget:add(c)
end

-- CPU: usage
local myusagewidget = wibox.widget.textbox()
vicious.register(myusagewidget, vicious.widgets.cpu, function(widget, args)
    return string.format("%02d", args[1]).."%" end, 1)
myusagewidget:connect_signal("button::release", function()
    local s = mouse.screen.index
    cput_widgets[s].visible = not cput_widgets[s].visible
end)

-- external events via "awesome-client"
function ext_event_handler(event, data)
    --debug_print("DBUS EVENT: "..event)
    if event == "acpi_jack" then
        awful.util.spawn(hcmd.s_pause)
        helpmod.fresh_volume_box()
    elseif event == "acpi_ac" and on_laptop then
        helpmod.fresh_battery_box()
    elseif event == "mp_stat" and data then
        --debug_print("status:"..data)
        if data == "Playing" then
            mympstate.image = beautiful.playing
        else
            mympstate.image = beautiful.paused
        end
        mympstate.visible = true
        mpspace.visible = true
    elseif event == "mp_quit" then
        mympstate.visible = false
        mpspace.visible = false
    elseif event == "net" then
        net_devs = helpmod.get_net_devices()
        --hfnc.print_table(net_devs, "netdevs")
    else
        event = event or "nil"
        debug_print('Wrong event string: "'..event..'"')
    end
end


-- Create a wibox for each screen and add it
-- @TAGLIST_BUTTON@
local taglist_buttons = gears.table.join(
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
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

-- @TASKLIST_BUTTON@
local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))

-- @DOC_WALLPAPER@
local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

-- @DOC_FOR_EACH_SCREEN@
awful.screen.connect_for_each_screen(function(s)
    local first_screen = (s.index == 1)

    -- Wallpaper
    set_wallpaper(s)

    -- connect to signals
    if first_screen then
        s:connect_signal("removed", function()
            debug_print_perm("a screen has been removed")
            update_screen_count()
        end)
        s:connect_signal("added", function()
            debug_print_perm("a screen has been added")
            update_screen_count()
        end)
    end

    -- Each screen has its own tag table.
    --awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
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
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = tasklist_buttons
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
            --mykeyboardlayout,
            space1,
            myusagewidget,
            separator)

    local ctc = wibox.container.background(mycputempwidget)
    if num_screen == 1 then ctc.visible = false end
    cput_widgets[s.index] = ctc
    rightl:add(ctc)

    rightl:add(mynetwidget) rightl:add(separator)
    if first_screen then rightl:add(mysystray) rightl:add(mystseparator) end
    rightl:add(myplacedmpstate) rightl:add(mpspace)
    rightl:add(myvolwidget)
    -- separator included
    if first_screen and on_laptop then rightl:add(myblwidget) end

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
root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
-- @DOC_GLOBAL_KEYBINDINGS@
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev,
              {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext,
              {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore,
              {description = "go back", group = "tag"}),

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
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end,
              {description = "show main menu", group = "awesome"}),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end,
              {description = "swap with next client by index", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end,
              {description = "swap with previous client by index", group = "client"}),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end,
              {description = "focus the next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end,
              {description = "focus the previous screen", group = "screen"}),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto,
              {description = "jump to urgent client", group = "client"}),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end,
        {description = "go back", group = "client"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end,
              {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              {description = "quit awesome", group = "awesome"}),

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

    awful.key({ modkey, "Control" }, "n",
              function ()
                  local c = awful.client.restore()
                  -- Focus restored client
                  if c then
                      client.focus = c
                      c:raise()
                  end
              end,
              {description = "restore minimized", group = "client"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end,
              {description = "run prompt", group = "launcher"}),


    -- Rename current tag
    awful.key({ modkey, "Shift" },   "t", function () rename_current_tag() end,
              {description = "rename current tag", group = "awesome"}),

    -- Reset all tags
    awful.key({ modkey, "Control" }, "t", function () reset_all_tags() end,
              {description = "reset tags", group = "awesome"}),

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

    -- Assign special keys
    awful.key({ "Control", "Mod1" }, "Delete", function()
        awful.util.spawn(hcmd.locker) end),
    awful.key({ }, "XF86AudioLowerVolume", function()
        helpmod.lower_volume() end),
    awful.key({ }, "XF86AudioRaiseVolume", function()
        helpmod.raise_volume() end),
    awful.key({ }, "XF86AudioMute", function()
        helpmod.toggle_mute() end),
    awful.key({ }, "XF86AudioNext", function()
        awful.util.spawn(hcmd.s_next)
        end),
    awful.key({ }, "XF86AudioPrev", function()
        awful.util.spawn(hcmd.s_prev)
        end),
    awful.key({ }, "XF86AudioPlay", function()
        awful.util.spawn(hcmd.s_playtoggle)
        end),
    awful.key({ }, "XF86Calculator", function()
        awful.util.spawn(hcmd.calculator) end),
    awful.key({ }, "XF86TouchpadToggle", function()
        if on_laptop then
            awful.util.spawn(hcmd.s_toggletp)
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

    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"})
)

-- @DOC_CLIENT_KEYBINDINGS@
clientkeys = gears.table.join(
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
        {description = "(un)maximize horizontally", group = "client"})
)

-- @DOC_NUMBER_KEYBINDINGS@
-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
local keycodes = {49, 10, 11, 12, 13, 14, 15, 16, 17, 18}
for index, kcode in pairs(keycodes)  do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. kcode,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[index]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..index, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. kcode,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[index]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #"..index, group = "tag"}),
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
                  {description = "move focused client to tag #"..index, group = "tag"}),
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
                  {description = "toggle focused client on tag #"..index, group = "tag"})
    )
end

-- @DOC_CLIENT_BUTTONS@
clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
-- @DOC_RULES@
awful.rules.rules = {
    -- @DOC_GLOBAL_RULE@
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     -- no_offscreen totally overriding under_mouse or centered, wa. added
                     placement = awful.placement.centered
                                --+awful.placement.no_offscreen
     }
    },

    -- @DOC_FLOATING_RULE@
    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
          "pinentry",
        },
        class = {
          "Arandr",
          "Blueman-manager",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "ConfigManager",  -- Thunderbird's about:config.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- @DOC_DIALOG_RULE@
    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = hcfg.titlebars_enabled }
    },

    -- Set Conky to be on a hidden tag without centering
    { rule = { class = "Conky" },
      properties = { placement = awful.placement.no_offscreen,
                     tag = hiddentag[1] } },

    -- Set Firefox to always map on www tag on def_screen
    { rule = { class = "Firefox" },
      properties = { screen = def_screen, tag = "www" } },

    -- Set Chrome to always map on www tag on last screen
    { rule = { class = "Google-chrome" },
      properties = { screen = num_screen, tag = "www" } },

    -- Set Evolution to always map to first tag on first screen
    { rule = { class = "Evolution" },
      properties = { screen = 1, tag = "head" } },

    -- Set Pidgin to always map to first tag and be br. floating on first screen
    { rule = { class = "Pidgin" },
      properties = { screen = 1, tag = "head",
                     floating = true,
                     placement = awful.placement.bottom_right } },

    -- Set Spotify to always map to 'kreat' tag on last screen
    { rule = { class = "Spotify" },
      properties = { screen = num_screen, tag = "kreat" } },

    -- Set qjackctl to always be floating
    { rule = { class = "qjackctl" },
      properties = { floating = true,
                     placement = awful.placement.bottom_right } },

}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
-- @DOC_MANAGE_HOOK@
client.connect_signal("manage", function (c)
    local shints = c.size_hints
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

--    debug_print_perm(string.format("name=%q\nhints=%s", c.name, hfnc.table_to_str(shints)))

    -- workaround for no_offscreen totally overriding under_mouse or centered
    if --awesome.startup and
      not shints.user_position
      and not shints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- @DOC_TITLEBARS@
-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = gears.table.join(
        awful.button({ }, 1, function()
            client.focus = c
            c:raise()
            awful.mouse.client.move(c)
        end),
        awful.button({ }, 3, function()
            client.focus = c
            c:raise()
            awful.mouse.client.resize(c)
        end)
    )

    awful.titlebar(c) : setup {
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

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c) then
        client.focus = c
    end
end)

-- @DOC_BORDER@
-- set unfocused to a little bit transparent
client.connect_signal("focus", function(c)
                                 c.border_color = beautiful.border_focus
                                 c.opacity = 1
                               end)
client.connect_signal("unfocus", function(c)
                                   c.border_color = beautiful.border_normal
                                   c.opacity = 0.96
                                 end)
-- }}}

-- vim: autoindent tabstop=8 shiftwidth=4 expandtab softtabstop=4 filetype=lua