----------------------------------------
--  Based on "Zenburn" awesome theme  --
--    By Adrian C. (anrxc)            --
----------------------------------------

-- Alternative icon sets and widget icons:
--  * http://awesome.naquadah.org/wiki/Nice_Icons

-- {{{ Main
local theme = {}
theme.wallpaper = "~/.config/awesome/theme/minimal-background.jpg"
-- }}}

-- {{{ Styles
theme.font      = "sans 8"

-- {{{ Base colors
theme.fg_normal  = "#DCDCCC"
theme.fg_focus   = "#DCDCCC"
theme.fg_urgent  = "#CC9393"

theme.bg_normal  = "#212121"
--theme.bg_focus   = "#363F3A"
theme.bg_focus   = "#003366"
theme.bg_urgent  = "#3F3F3F"

theme.bg_systray = "#212121"
-- }}}

-- {{{ Borders
theme.border_width  = 0
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

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- [taglist|tasklist]_[bg|fg]_[focus|urgent]
-- titlebar_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- Example:
--theme.taglist_bg_focus = "#CC9393"
-- }}}

-- {{{ Widgets
-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
--theme.fg_widget        = "#AECF96"
--theme.fg_center_widget = "#88A175"
--theme.fg_end_widget    = "#FF5656"
--theme.bg_widget        = "#494B4F"
--theme.border_widget    = "#3F3F3F"
-- }}}

-- {{{ Mouse finder
theme.mouse_finder_color = "#CC9393"
-- mouse_finder_[timeout|animate_timeout|radius|factor]
-- }}}

-- {{{ Menu
-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_height = 15
theme.menu_width  = 100
-- }}}

-- {{{ Icons
-- {{{ Taglist
theme.taglist_squares_sel   = "~/.config/awesome/theme/taglist/squarefz.png"
theme.taglist_squares_unsel = "~/.config/awesome/theme/taglist/squarez.png"
--theme.taglist_squares_resize = "false"
-- }}}

-- {{{ Misc
theme.awesome_icon           = "~/.config/awesome/theme/awesome-icon.png"
theme.menu_submenu_icon      = "~/.config/awesome/theme/submenu.png"
-- }}}

-- {{{ Layout
theme.layout_tile       = "~/.config/awesome/theme/layouts/tile.png"
theme.layout_tileleft   = "~/.config/awesome/theme/layouts/tileleft.png"
theme.layout_tilebottom = "~/.config/awesome/theme/layouts/tilebottom.png"
theme.layout_tiletop    = "~/.config/awesome/theme/layouts/tiletop.png"
theme.layout_fairv      = "~/.config/awesome/theme/layouts/fairv.png"
theme.layout_fairh      = "~/.config/awesome/theme/layouts/fairh.png"
theme.layout_spiral     = "~/.config/awesome/theme/layouts/spiral.png"
theme.layout_dwindle    = "~/.config/awesome/theme/layouts/dwindle.png"
theme.layout_max        = "~/.config/awesome/theme/layouts/max.png"
theme.layout_fullscreen = "~/.config/awesome/theme/layouts/fullscreen.png"
theme.layout_magnifier  = "~/.config/awesome/theme/layouts/magnifier.png"
theme.layout_floating   = "~/.config/awesome/theme/layouts/floating.png"
theme.layout_cornernw   = "~/.config/awesome/theme/layouts/cornernw.png"
theme.layout_cornerne   = "~/.config/awesome/theme/layouts/cornerne.png"
theme.layout_cornersw   = "~/.config/awesome/theme/layouts/cornersw.png"
theme.layout_cornerse   = "~/.config/awesome/theme/layouts/cornerse.png"
-- }}}

-- {{{ Titlebar
theme.titlebar_close_button_focus  = "~/.config/awesome/theme/titlebar/close_focus.png"
theme.titlebar_close_button_normal = "~/.config/awesome/theme/titlebar/close_normal.png"

theme.titlebar_ontop_button_focus_active  = "~/.config/awesome/theme/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = "~/.config/awesome/theme/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive  = "~/.config/awesome/theme/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = "~/.config/awesome/theme/titlebar/ontop_normal_inactive.png"

theme.titlebar_sticky_button_focus_active  = "~/.config/awesome/theme/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = "~/.config/awesome/theme/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive  = "~/.config/awesome/theme/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = "~/.config/awesome/theme/titlebar/sticky_normal_inactive.png"

theme.titlebar_floating_button_focus_active  = "~/.config/awesome/theme/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = "~/.config/awesome/theme/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive  = "~/.config/awesome/theme/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = "~/.config/awesome/theme/titlebar/floating_normal_inactive.png"

theme.titlebar_maximized_button_focus_active  = "~/.config/awesome/theme/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = "~/.config/awesome/theme/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = "~/.config/awesome/theme/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = "~/.config/awesome/theme/titlebar/maximized_normal_inactive.png"
-- }}}
-- }}}

return theme
