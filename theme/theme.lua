----------------------------------------
--  Based on "Zenburn" awesome theme  --
--    By Adrian C. (anrxc)            --
----------------------------------------

local themes_path = require("gears.filesystem").get_configuration_dir()
local dpi = require("beautiful.xresources").apply_dpi

-- {{{ Main
local theme = {}
theme.wallpaper = themes_path .. "awesome-wallpaper"
-- }}}

-- {{{ Styles
theme.font      = "sans 8"
-- }}}

-- {{{ Base colors
theme.fg_normal  = "#DCDCCC"
theme.fg_focus   = "#DCDCCC"
theme.fg_urgent  = "#CC9393"

theme.bg_normal  = "#212121"
theme.bg_focus   = "#003366"
theme.bg_urgent  = "#3F3F3F"

theme.bg_systray = "#212121"
-- }}}

-- {{{ Borders
theme.border_width  = 0
theme.useless_gap   = dpi(0)
--theme.border_width  = dpi(2)
theme.border_normal = "#FFFFFF"
theme.border_focus  = "#FECA00"
theme.border_marked = "#CC9393"
-- }}}

-- {{{ Titlebars
theme.titlebar_bg_focus  = "#3F3F3F"
theme.titlebar_bg_normal = "#3F3F3F"
-- }}}

-- {{{ Prompts
theme.prompt_bg = "#000000"
theme.prompt_fg = "#FF0000"
-- }}}

-- {{{ Widgets
theme.playing = themes_path .. "theme/icons/play.png"
theme.paused = themes_path .. "theme/icons/pause.png"
-- }}}

-- {{{ Widgets
theme.notification_icon_size = 140
-- }}}

-- {{{ Mouse finder
theme.mouse_finder_color = "#CC9393"
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
theme.awesome_icon          = themes_path .. "theme/awesome-icon.png"
theme.menu_submenu_icon     = themes_path .. "theme/submenu.png"
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
