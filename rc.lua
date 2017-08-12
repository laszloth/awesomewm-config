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
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
-- Others
local vicious = require("vicious")
-- own helpers
local hf = require("helpers")

-- Load Debian menu entries
require("debian.menu")

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
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Autorun script start
-- TODO return value will show not found commands, handle that
awful.util.spawn_with_shell("~/.config/awesome/scripts/autorun.sh &>/dev/null")
-- }}}


-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
--beautiful.init("/usr/share/awesome/themes/default/theme.lua")
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
local def_screen = 1
local numCores = awful.util.pread("awk '/cpu cores/ {print $4}' /proc/cpuinfo | uniq")

-- helper functions
debug_print = function (msg)
    naughty.notify({ preset = naughty.config.presets.critical,
        title = "DEBUG MESSAGE",
        text = msg })
end

notify_print = function (msg)
    naughty.notify({ preset = naughty.config.presets.normal,
        title = "notification",
        text = msg })
end

updateScreenCount = function(s)
    if screen.count() > 1 then
        def_screen = 2
    end
    debug_print("updateScreenCount: def_screen="..def_screen)
end

eventHandler = function(e)
    --debug_print("DBUS EVENT: "..e)
    if e == "acpi_jack" then
        myvolwidget:set_markup(hf.getVolumeLevel())
    elseif e == "acpi_ac" then
        mybatwidget:set_markup(hf.getBatteryLevel())
    else
        debug_print("Wrong event string:"..e)
    end
end

-- Default screen settings for Firefox and others
updateScreenCount()
-- TODO signals don't seem to work
--screen[1]:connect_signal("added", updateScreenCount)
--screen[1]:connect_signal("removed", updateScreenCount)

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
--    awful.layout.suit.tile.left,
--    awful.layout.suit.tile.bottom,
--    awful.layout.suit.tile.top,
--    awful.layout.suit.fair,
--    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
-- Screen 1 is kinda special
tags[1] = awful.tag({ "evol", "main", "www", "term", "kreat", "riddler" }, s,
            { layouts[1], -- evol
              layouts[1], -- main
              layouts[3], -- www
              layouts[2], -- term
              layouts[1], -- kreat
              layouts[1], -- riddler
            })
-- Screen n isn't
for s = 2, screen.count() do
    tags[s] = awful.tag({ "null", "main", "www", "term", "kreat", "riddler" }, s,
            { layouts[1], -- null
              layouts[1], -- main
              layouts[3], -- www
              layouts[2], -- term
              layouts[1], -- kreat
              layouts[1], -- riddler
            })
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "apps", debian.menu.Debian_menu.Debian },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock("%Y-%m-%d %H:%M:%S", 1)

-- Create backlight widget
myblwidget = wibox.widget.textbox()
myblwidget:set_markup(hf.getBacklightLevel())
--myblwidget.visible = false

-- TODO start timer to hide textbox
--mybltimer = timer ({ timeout = 2 })
--mybltimer:connect_signal("timeout", function() myblwidget.visible = false end)

-- Create volume widget
myvoltimer = timer({ timeout = 120 })
myvoltimer:connect_signal("timeout", function() myvolwidget:set_markup(hf.getVolumeLevel()) end)

myvolwidget = wibox.widget.textbox()
myvolwidget:set_markup(hf.getVolumeLevel())
myvoltimer:start()

-- Create battery widget
mybattimer = timer({ timeout = 90 })
mybattimer:connect_signal("timeout", function() mybatwidget:set_markup(hf.getBatteryLevel()) end)

mybatwidget = wibox.widget.textbox()
mybatwidget:set_markup(hf.getBatteryLevel())
mybattimer:start()

-- Create net widget
mynetwidget = wibox.widget.textbox()
vicious.register(mynetwidget, vicious.widgets.net, hf.getNetworkStats, 1)

-- Create CPU widgets
cpudata = {}

-- CPU: usage
cpudata.usage = wibox.widget.textbox()
vicious.register(cpudata.usage, vicious.widgets.cpu, function(widget, args)
    return string.format("%02d", args[1]).."%" end, 1)

-- CPU: thermal
cpudata.temp = {}
for i = 2,1+numCores do
    local c = wibox.widget.textbox()
    vicious.register(c, vicious.widgets.thermal,
        function(widget, args) return hf.getCoreTempText(args[1], i) end,
        1, { 'coretemp.0/hwmon/hwmon1', 'core', 'temp'..i..'_input' })

    table.insert(cpudata.temp, c)
end

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({
                                                      theme = { width = 250 }
                                                  })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do
    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt({ prompt = ' Execute: ' })
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "bottom", height = 24, screen = s })

    -- {{{ spaces and separator
    local space1 = wibox.widget.textbox()
    local space2 = wibox.widget.textbox()
    local space3 = wibox.widget.textbox()
    local separator = wibox.widget.textbox()

    local spacetext = ' '
    local spacetext2 = '  '
    local spacetext3 = '   '
    local separtext = ' | '

    space1:set_text(spacetext)
    space2:set_text(spacetext2)
    space3:set_text(spacetext3)
    separator:set_text(separtext)
    -- }}}

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    --left_layout:add(mylauncher)
    left_layout:add(mytaglist[s])
    local dec_prompt = wibox.widget.background(mypromptbox[s])
    dec_prompt:set_fg(hf.prompt_fg)
    dec_prompt:set_bg(hf.prompt_bg)
    left_layout:add(dec_prompt)

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    right_layout:add(separator)
    right_layout:add(cpudata.usage)
    right_layout:add(separator)
    for i,c in ipairs(cpudata.temp) do
        right_layout:add(c)
        right_layout:add(separator)
    end
    right_layout:add(mynetwidget)
    right_layout:add(separator)
    if s == 1 then
        right_layout:add(wibox.widget.systray())
        right_layout:add(separator)
        right_layout:add(myvolwidget)
        right_layout:add(separator)
        right_layout:add(myblwidget)
        right_layout:add(separator)
        right_layout:add(mybatwidget)
        right_layout:add(separator)
    end
    right_layout:add(mytextclock)
    right_layout:add(space1)
    right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)
end
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
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    -- Assign special keys
    awful.key({ "Control", "Mod1" }, "Delete", function()
        awful.util.spawn( locker_cmd ) end),
    awful.key({ }, "XF86AudioLowerVolume", function()
        awful.util.spawn( "pactl set-sink-volume 0 -2%" )
        myvolwidget:set_markup(hf.getVolumeLevel()) end),
    awful.key({ }, "XF86AudioRaiseVolume", function()
        if hf.getVolumeLevel(1) >= hf.volume_limit then
            return
        end
        awful.util.spawn( "pactl set-sink-volume 0 +2%" )
        myvolwidget:set_markup(hf.getVolumeLevel()) end),
    awful.key({ }, "XF86AudioMute", function()
        awful.util.spawn( "pactl set-sink-mute 0 toggle" )
        myvolwidget:set_markup(hf.getVolumeLevel()) end),
    awful.key({ }, "XF86AudioNext", function()
        awful.util.spawn( "dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next" ) end),
    awful.key({ }, "XF86AudioPrev", function()
        awful.util.spawn( "dbus-send --type=method_call --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous" ) end),
    awful.key({ }, "XF86AudioPlay", function()
        awful.util.spawn_with_shell( "~/.config/awesome/scripts/XF86Play.sh" ) end),
    awful.key({ }, "XF86Calculator", function()
        awful.util.spawn( "gnome-calculator" ) end),
    awful.key({ }, "XF86TouchpadToggle", function()
        awful.util.spawn_with_shell( "~/.config/awesome/scripts/dell_touch.sh" ) end),
    awful.key({ }, "XF86MonBrightnessDown", function()
        awful.util.spawn( "xbacklight -dec 10" )
        myblwidget:set_markup(hf.getBacklightLevel())
        end),
    awful.key({ }, "XF86MonBrightnessUp", function()
        awful.util.spawn( "xbacklight -inc 10" )
        myblwidget:set_markup(hf.getBacklightLevel())
        end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.movetotag(tag)
                          end
                     end
                  end),
        -- Toggle tag.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = awful.tag.gettags(client.focus.screen)[i]
                          if tag then
                              awful.client.toggletag(tag)
                          end
                      end
                  end))
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
                     buttons = clientbuttons } },

    -- Set Firefox to always map on www tag on def_screen
    { rule = { class = "Firefox" },
      properties = { tag = tags[def_screen][3] } },

    -- Set Evolution to always map to 'evol' tag on first screen
    { rule = { class = "Evolution" },
      properties = { tag = tags[1][1] } },

    -- Set Pidgin to always map to 'evol' tag and be floating on first screen
    { rule = { class = "Pidgin" },
      properties = { tag = tags[1][1],
                     floating = true } },
    -- Set Spotify to always map to 'kreat' tag on def_screen
    { rule = { class = "Spotify" },
      properties = { tag = tags[def_screen][5] } },

    -- defaults
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },

}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    elseif not c.size_hints.user_position and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count change
        awful.placement.no_offscreen(c)
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
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

        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))
        left_layout:buttons(buttons)

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c):set_widget(layout)
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
