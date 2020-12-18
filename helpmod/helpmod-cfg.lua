local hcfg = {}

-- thresholds
hcfg.cpu_temp_high           = 85
hcfg.cpu_temp_mid            = 65

hcfg.volume_max              = 175
hcfg.volume_high             = 75
hcfg.volume_mid              = 50
hcfg.volume_slight           = 10

hcfg.battery_low             = 20
hcfg.battery_low_notif_gap   = 5

-- initial values
hcfg.ext_sc_init_val         = 20

-- labels
hcfg.label_speaker           = 'SPEAKER'
hcfg.label_jack              = 'JACK'
hcfg.label_ext               = 'EXT'
hcfg.label_bt                = 'BT'
hcfg.label_usb               = 'USB'
hcfg.label_muted             = 'MUTED'

-- colors
hcfg.warn_color              = '#FECA00'
hcfg.crit_color              = '#FF0000'

hcfg.net_download_color      = '#E60012'
hcfg.net_upload_color        = '#41F468'
hcfg.net_tunnel_color        = '#D31010'

hcfg.cpu_temp_low_color      = '#7FAE5A'
hcfg.cpu_temp_medium_color   = hcfg.warn_color
hcfg.cpu_temp_high_color     = hcfg.crit_color

hcfg.volume_high_color       = hcfg.crit_color
hcfg.volume_mid_color        = hcfg.warn_color
hcfg.volume_mute_color       = '#5C5C5C'
hcfg.volume_ext_color        = '#BA4100'
hcfg.volume_bt_color         = '#0083FD'
hcfg.volume_usb_color        = '#005094'

hcfg.battery_low_color       = hcfg.crit_color
hcfg.battery_charge_color    = '#00FF00'
hcfg.ac_plugged_color        = '#7FAE5A'

-- additional conf.
hcfg.titlebars_enabled       = false

hcfg.nw_decimal_places       = 2

hcfg.bl_step                 = 5 --percent
hcfg.vol_step                = 2 --percent
hcfg.ext_step                = 25 --percent

-- timeouts
hcfg.backlight_timeout       = 2.5
hcfg.volume_timeout          = 120
hcfg.battery_timeout         = 30

-- spacing
hcfg.space_txt  = ' '
hcfg.space_txt2 = '  '
hcfg.space_txt3 = '   '
hcfg.separ_txt  = ' | '

return hcfg

-- vim: autoindent tabstop=8 shiftwidth=4 expandtab softtabstop=4 filetype=lua
