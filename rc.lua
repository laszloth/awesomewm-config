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
-- Others
local vicious = require("vicious")
-- C API
local capi = { awesome = awesome }
-- own helpmod
local helpmod = require("helpmod")

-- Load Debian menu entries
--require("debian.menu")

-- {{{ Error handling
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

-- {{{ Autorun script start
awful.spawn.with_shell("~/.config/awesome/scripts/autorun.sh &>/dev/null")
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
--beautiful.init(awful.util.get_themes_dir() .. "default/theme.lua")
beautiful.init("~/.config/awesome/theme/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal    = "konsole"
editor      = "vim"
editor_cmd  = terminal .. " -e " .. editor
locker_cmd  = "light-locker-command -l"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Widget variables
local num_screen = 1
local def_screen = 1
local numCores = helpmod.getCPUCoreCnt()

-- {{{ Helper functions
function debug_print(msg)
    naughty.notify({ preset = naughty.config.presets.critical,
        timeout = 5,
        title = "DEBUG MESSAGE",
        text = tostring(msg) })
end

local function debug_print_perm(msg)
    naughty.notify({ preset = naughty.config.presets.critical,
        title = "DEBUG MESSAGE",
        text = tostring(msg) })
end

local function notify_print(msg)
    naughty.notify({ preset = naughty.config.presets.normal,
        title = "notification",
        text = tostring(msg) })
end

local function updateScreenCount(s)
    num_screen = screen.count()
    def_screen = math.floor(num_screen / 3) + 1
    --debug_print("num_screen="..num_screen.."\ndef_screen="..def_screen)
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

-- Default screen settings for Firefox and others
updateScreenCount()

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
-- }}}

-- {{{ Menu
-- Create a launcher widget and a main menu
myawesomemenu = {
   { "hotkeys", function() return false, hotkeys_popup.show_help end},
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function() awesome.quit() end}
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    --{ "Debian", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- Keyboard map indicator and switcher
local mykeyboardlayout = awful.widget.keyboardlayout()

-- {{{ Wibar
-- Create a textclock widget
local mytextclock = wibox.widget.textclock("%Y-%m-%d %H:%M:%S", 1)

-- Create systray and its separator
local mystseparator = wibox.widget.textbox()
mystseparator.text = helpmod.separtxt
local mysystray = wibox.widget.systray()
mysystray:connect_signal("widget::redraw_needed", function()
    local entries = capi.awesome.systray()
    --debug_print("systray entries="..entries)
    if entries == 0 then
        mystseparator.visible = false
    else
        mystseparator.visible = true
    end
end)

-- Create backlight widget
local myblwidget = wibox.widget.textbox()
helpmod.freshBacklightBox(myblwidget)

-- timer to hide backlight textbox
local mybltimer = gears.timer { timeout = 2.5, }
mybltimer:connect_signal("timeout", function()
    --debug_print_perm("mybltimer expired")
    myblwidget.visible = false
    mybltimer:stop() end)
mybltimer:start()

-- Create volume widget
local myvolwidget = wibox.widget.textbox()
local myvoltimer = gears.timer { timeout = 120, }
myvoltimer:connect_signal("timeout", function()
    --debug_print_perm("myvoltimer expired")
    helpmod.freshVolumeBox(myvolwidget)
end)
myvolwidget:connect_signal("button::release", function()
    awful.util.spawn("pactl set-sink-mute 0 toggle")
    helpmod.freshVolumeBox(myvolwidget)
end)

helpmod.freshVolumeBox(myvolwidget)
myvoltimer:start()

-- Create battery widget
local mybatwidget = wibox.widget.textbox()
local mybattimer = gears.timer { timeout = 90, }
mybattimer:connect_signal("timeout", function()
    --debug_print_perm("mybattimer expired")
    helpmod.freshBatteryBox(mybatwidget)
end)

helpmod.freshBatteryBox(mybatwidget)
mybattimer:start()

-- Create net widget
local mynetwidget = wibox.widget.textbox()
vicious.register(mynetwidget, vicious.widgets.net, helpmod.getNetworkStats, 1)

-- Create CPU widgets
local cpudata = {}

-- CPU: usage
cpudata.usage = wibox.widget.textbox()
vicious.register(cpudata.usage, vicious.widgets.cpu, function(widget, args)
    return string.format("%02d", args[1]).."%" end, 1)

-- CPU: thermal
local cpud_temp = {}
for i = 2,1+numCores do
    local c = wibox.widget.textbox()
    vicious.register(c, vicious.widgets.thermal,
        function(widget, args) return helpmod.getCoreTempText(args[1], i) end,
        1, { 'coretemp.0/hwmon/hwmon1', 'core', 'temp'..i..'_input' })

    table.insert(cpud_temp, c)
end

function eventHandler(e)
    --debug_print("DBUS EVENT: "..e)
    if e == "acpi_jack" then
        helpmod.freshVolumeBox(myvolwidget)
    elseif e == "acpi_ac" then
        helpmod.freshBatteryBox(mybatwidget)
    else
        debug_print("Wrong event string:"..e)
    end
end

-- Create a wibox for each screen and add it
local taglist_buttons = awful.util.table.join(
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

local tasklist_buttons = awful.util.table.join(
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

awful.screen.connect_for_each_screen(function(s)
    local firstScreen = false
    local firstTag = "null"

    -- Wallpaper
    set_wallpaper(s)

    if s.index == 1 then
        firstScreen = true
        firstTag = "evol"
        s:connect_signal("removed", function()
            debug_print("screen removed")
            updateScreenCount()
        end)
        s:connect_signal("added", function()
            debug_print("screen added")
            updateScreenCount()
        end)
    end

    -- Each screen has its own tag table.
    --awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[1])
    awful.tag({ firstTag, "main", "www", "term", "kreat", "riddler" }, s,
            { awful.layout.layouts[1], -- var. firstTag
              awful.layout.layouts[1], -- main
              awful.layout.layouts[3], -- www
              awful.layout.layouts[2], -- term
              awful.layout.layouts[3], -- kreat
              awful.layout.layouts[1], -- riddler
            })

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt({ prompt = ' Execute: ' })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "bottom", height = 24, screen = s })

    -- {{{ spaces and separator
    local space1 = wibox.widget.textbox()
    space1.text = helpmod.spacetxt
    --local space2 = wibox.widget.textbox()
    --space2.text = helpmod.spacetxt2
    --local space3 = wibox.widget.textbox()
    --space3.text = helpmod.spacetxt3
    local separator = wibox.widget.textbox()
    separator.text = helpmod.separtxt

    -- }}}

    local dprompt = wibox.container.background(s.mypromptbox)
    dprompt:set_fg(helpmod.prompt_fg)
    dprompt:set_bg(helpmod.prompt_bg)

    -- Add widgets to the wibox
    local leftl = { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            --mylauncher,
            s.mytaglist,
            --s.mypromptbox,
            dprompt,
    }
    local middlel = s.mytasklist
    local rightl = { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            --mykeyboardlayout,
            space1,
            cpudata.usage,
    }

    if firstScreen then
        table.insert(rightl, separator)
        for key,val in pairs(cpud_temp) do table.insert(rightl, val) table.insert(rightl, separator) end
        table.insert(rightl, mynetwidget) table.insert(rightl, separator)
        table.insert(rightl, mysystray) table.insert(rightl, mystseparator)
        table.insert(rightl, myvolwidget)
        -- separator included
        table.insert(rightl, myblwidget)
    else
        table.insert(rightl, separator)
        table.insert(rightl, mynetwidget) table.insert(rightl, separator)
        table.insert(rightl, myvolwidget)
    end
    table.insert(rightl, separator)
    table.insert(rightl, mybatwidget) table.insert(rightl, separator)
    table.insert(rightl, mytextclock) table.insert(rightl, space1)
    table.insert(rightl, s.mylayoutbox)

    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        leftl,
        middlel,
        rightl,
    }

end)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
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
        awful.util.spawn(locker_cmd) end),
    awful.key({ }, "XF86AudioLowerVolume", function()
        awful.util.spawn("pactl set-sink-volume 0 -2%")
        helpmod.freshVolumeBox(myvolwidget) end),
    awful.key({ }, "XF86AudioRaiseVolume", function()
        awful.util.spawn("pactl set-sink-volume 0 +2%")
        helpmod.freshVolumeBox(myvolwidget) end),
    awful.key({ }, "XF86AudioMute", function()
        awful.util.spawn("pactl set-sink-mute 0 toggle")
        helpmod.freshVolumeBox(myvolwidget) end),
    awful.key({ }, "XF86AudioNext", function()
        awful.util.spawn("dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next") end),
    awful.key({ }, "XF86AudioPrev", function()
        awful.util.spawn("dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous") end),
    awful.key({ }, "XF86AudioPlay", function()
        awful.spawn.with_shell("~/.config/awesome/scripts/XF86Play.sh") end),
    awful.key({ }, "XF86Calculator", function()
        awful.util.spawn("gnome-calculator") end),
    awful.key({ }, "XF86TouchpadToggle", function()
        awful.spawn.with_shell("~/.config/awesome/scripts/dell_touch.sh") end),
    awful.key({ }, "XF86MonBrightnessDown", function()
        awful.util.spawn("xbacklight -dec 10")
        helpmod.freshBacklightBox(myblwidget)
        mybltimer:again()
        end),
    awful.key({ }, "XF86MonBrightnessUp", function()
        awful.util.spawn("xbacklight -inc 10")
        helpmod.freshBacklightBox(myblwidget)
        mybltimer:again()
        end),

    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end,
              {description = "show the menubar", group = "launcher"})
)

clientkeys = awful.util.table.join(
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
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen()               end,
              {description = "move to screen", group = "client"}),
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
        {description = "maximize", group = "client"})
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },

    -- Floating clients.
    { rule_any = {
        instance = {
          "DTA",  -- Firefox addon DownThemAll.
          "copyq",  -- Includes session name in class.
        },
        class = {
          "Arandr",
          "Gpick",
          "Kruler",
          "MessageWin",  -- kalarm.
          "Sxiv",
          "Wpa_gui",
          "pinentry",
          "veromix",
          "xtightvncviewer"},

        name = {
          "Event Tester",  -- xev.
        },
        role = {
          "AlarmWindow",  -- Thunderbird's calendar.
          "pop-up",       -- e.g. Google Chrome's (detached) Developer Tools.
        }
      }, properties = { floating = true }},

    -- Add titlebars to normal clients and dialogs
    { rule_any = {type = { "normal", "dialog" }
      }, properties = { titlebars_enabled = false }
    },

    -- Set Firefox to always map on www tag on def_screen
    { rule = { class = "Firefox" },
      properties = { screen = def_screen, tag = "www" } },

    -- Set Chrome to always map on www tag on last screen
    { rule = { class = "Google-chrome" },
      properties = { screen = num_screen, tag = "www" } },

    -- Set Evolution to always map to first tag on first screen
    { rule = { class = "Evolution" },
      properties = { screen = 1, tag = "evol" } },

    -- Set Pidgin to always map to 'evol' tag and be floating on first screen
    { rule = { class = "Pidgin" },
      properties = { screen = 1, tag = "evol",
                     floating = true } },
    -- Set Spotify to always map to 'kreat' tag on def_screen
    { rule = { class = "Spotify" },
      properties = { screen = def_screen, tag = "kreat" } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup and
      not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
    -- buttons for the titlebar
    local buttons = awful.util.table.join(
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
