# awesomewm-config
configuration for awesome window manager

based on awesomewm's awesomerc.lua and zenburn theme

## package dependencies
- archlinux-wallpaper
- bc
- gnome-calculator
- konsole
- laptop-detect
- physlock
- pulseaudio
- vim
- xbacklight
- xcompmgr

## todo
- [ ] remove under_mouse/centered+no_offscreen workaround
- [ ] remove workaround for konsole always being maximized
- [ ] add separate volume thresholds for different targets
- [ ] add borders, but hide 'em with one tiling client
- [ ] better dynamic network device support
- [ ] add disk IO widget

## done
- [x] define multiple mouse button actions [volume & playstate]
- [x] rxmas local vars
- [x] few "no sound" labels generated on quick volume change
- [x] add formatting functions [foreground is used only curr.]
- [x] change usb checks & functions to non-pci ones
- [x] handle different usb soundcards [regarding initial volume]
- [x] add new module for helper functions only
- [x] make audio info passing more robust
- [x] use sink name instead of index
- [x] remove widget argument from fresh functions
- [x] remove second argument from fresh functions
- [x] usb sound card: set initial volume
- [x] rebase theme
- [x] rebase rc.lua with awesomerc.lua
- [x] add event based net if refresh
- [x] more dynamic tag names and layouts config
- [x] low battery warning
- [x] quick setting of tag names
- [x] volume can be a little bit off sync on rapid vol. up/down presses
- [x] make volume buttons more flexible for usb sound card
- [x] support for usb sound card
- [x] CPU temp visible only on the screen where it was clicked
- [x] support for dynamic net interfaces (e.g. tun0)
- [x] clean up adding wibox widgets
- [x] smaller notification with its image resized
- [x] detect network dev names
- [x] disable systray if empty
- [x] enable transparency for conky (X_ChangeWindowAttributes error)
- [x] don't show conky on taglist
- [x] don't move conky to center on awesome restart

## maybe
- [ ] hide base net if if there is a tunnel
- [ ] then show base net if on click
- [ ] keycode to keysym

## deleted
- [x] remove relative volume handling [much slower and complicated due to callbacks]
