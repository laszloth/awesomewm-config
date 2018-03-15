# awesomewm-config
configuration for awesome window manager

based on awesome's awesomerc.lua and zenburn theme

## todo
- [ ] remove under_mouse/centered+no_offscreen workaround
- [ ] remove relative volume handling
- [ ] usb sound card: set initial volume
- [ ] keycode to keysym
- [ ] use sink name instead of index
- [ ] add new module for helper functions only
- [ ] remove widget argument from fresh functions
- [ ] remove second argument from fresh functions
- [ ] make audio info passing more robust

## done
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
