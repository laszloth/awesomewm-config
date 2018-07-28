----------------------------------------
--  Based on "Zenburn" awesome theme  --
--    By Adrian C. (anrxc)            --
----------------------------------------

local themes_path = require("gears.filesystem").get_configuration_dir()
local dpi = require("beautiful.xresources").apply_dpi
local colors = {
    red     = "#ff0000",
    green   = "#00ff00",
    blue    = "#0000ff",
    black   = "#000000",
    grey25  = "#3f3f3f",
    grey50  = "#7f7f7f",
    grey75  = "#bfbfbf",
    white   = "#ffffff",

    base    = "#212121",
    main    = "#003366",
    test    = "#cc9393",
    lightgrey = "#dcdccc",
    lightblue = "#1883f3",
}

-- {{{ Main
local theme = {}
theme.wallpaper = themes_path .. "awesome-wallpaper"
-- }}}

-- {{{ Styles
theme.font      = "sans 8"
-- }}}

-- {{{ Basic colors
theme.fg_normal  = colors.lightgrey
theme.fg_focus   = colors.lightgrey
theme.fg_urgent  = colors.test

theme.bg_normal  = colors.base
theme.bg_focus   = colors.main
theme.bg_urgent  = colors.grey25

theme.bg_systray = colors.base

-- }}}

-- {{{ Borders
theme.useless_gap   = dpi(0)
theme.border_width  = dpi(1)
theme.border_normal = colors.base
theme.border_focus  = colors.lightblue
theme.border_marked = colors.test
theme.fullscreen_hide_border = true
theme.maximized_hide_border = true
-- }}}

-- {{{ Titlebars
theme.titlebar_bg_focus  = colors.grey25
theme.titlebar_bg_normal = colors.grey25
-- }}}

-- {{{ Prompts
theme.prompt_bg = colors.black
theme.prompt_fg = colors.red
-- }}}

-- {{{ Widgets
theme.notification_icon_size = 140
-- }}}

-- {{{ Mouse finder
theme.mouse_finder_color = colors.test
-- mouse_finder_[timeout|animate_timeout|radius|factor]
-- }}}

-- {{{ Menu
-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_height = dpi(15)
theme.menu_width  = dpi(100)
-- }}}

-- {{{ Icons
-- {{{ Taglist
theme.taglist_squares_sel   = themes_path .. "theme/taglist/squarefz.png"
theme.taglist_squares_unsel = themes_path .. "theme/taglist/squarez.png"
--theme.taglist_squares_resize = "false"
-- }}}

-- {{{ Misc
theme.awesome_icon      = themes_path .. "theme/awesome-icon.png"
theme.menu_submenu_icon = themes_path .. "theme/submenu.png"
theme.play              = themes_path .. "theme/icons/play.png"
theme.pause             = themes_path .. "theme/icons/pause.png"
-- }}}

-- {{{ Layout
theme.layout_tile       = themes_path .. "theme/layouts/tile.png"
theme.layout_tileleft   = themes_path .. "theme/layouts/tileleft.png"
theme.layout_tilebottom = themes_path .. "theme/layouts/tilebottom.png"
theme.layout_tiletop    = themes_path .. "theme/layouts/tiletop.png"
theme.layout_fairv      = themes_path .. "theme/layouts/fairv.png"
theme.layout_fairh      = themes_path .. "theme/layouts/fairh.png"
theme.layout_spiral     = themes_path .. "theme/layouts/spiral.png"
theme.layout_dwindle    = themes_path .. "theme/layouts/dwindle.png"
theme.layout_max        = themes_path .. "theme/layouts/max.png"
theme.layout_fullscreen = themes_path .. "theme/layouts/fullscreen.png"
theme.layout_magnifier  = themes_path .. "theme/layouts/magnifier.png"
theme.layout_floating   = themes_path .. "theme/layouts/floating.png"
theme.layout_cornernw   = themes_path .. "theme/layouts/cornernw.png"
theme.layout_cornerne   = themes_path .. "theme/layouts/cornerne.png"
theme.layout_cornersw   = themes_path .. "theme/layouts/cornersw.png"
theme.layout_cornerse   = themes_path .. "theme/layouts/cornerse.png"
-- }}}

-- {{{ Titlebar
theme.titlebar_close_button_focus  = themes_path .. "theme/titlebar/close_focus.png"
theme.titlebar_close_button_normal = themes_path .. "theme/titlebar/close_normal.png"

theme.titlebar_minimize_button_normal = themes_path .. "theme/titlebar/minimize_normal.png"
theme.titlebar_minimize_button_focus  = themes_path .. "theme/titlebar/minimize_focus.png"

theme.titlebar_ontop_button_focus_active  = themes_path .. "theme/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = themes_path .. "theme/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive  = themes_path .. "theme/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = themes_path .. "theme/titlebar/ontop_normal_inactive.png"

theme.titlebar_sticky_button_focus_active  = themes_path .. "theme/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = themes_path .. "theme/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive  = themes_path .. "theme/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = themes_path .. "theme/titlebar/sticky_normal_inactive.png"

theme.titlebar_floating_button_focus_active  = themes_path .. "theme/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = themes_path .. "theme/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive  = themes_path .. "theme/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = themes_path .. "theme/titlebar/floating_normal_inactive.png"

theme.titlebar_maximized_button_focus_active  = themes_path .. "theme/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = themes_path .. "theme/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = themes_path .. "theme/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = themes_path .. "theme/titlebar/maximized_normal_inactive.png"
-- }}}
-- }}}

return theme

-- vim: autoindent tabstop=8 shiftwidth=4 expandtab softtabstop=4 filetype=lua
