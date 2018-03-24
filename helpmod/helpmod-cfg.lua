local hcfg = {}

-- thresholds
hcfg.cpu_temp_high           = 85
hcfg.cpu_temp_mid            = 55

hcfg.volume_high             = 65
hcfg.volume_mid              = 40

hcfg.battery_low             = 20
hcfg.battery_low_notif_gap   = 5

-- initial values
hcfg.usb_init_val            = 20

-- labels
hcfg.label_speaker           = 'SPKR:'
hcfg.label_jack              = 'JACK:'
hcfg.label_usb               = 'USB:'
hcfg.label_muted             = 'MUTED:'

-- colors
hcfg.warn_color              = '#FECA00'
hcfg.crit_color              = '#FF0000'

hcfg.net_download_color      = '#41F468'
hcfg.net_upload_color        = '#4179F4'
hcfg.net_tunnel_color        = '#D31010'

hcfg.cpu_temp_low_color      = '#7FAE5A'
hcfg.cpu_temp_medium_color   = hcfg.warn_color
hcfg.cpu_temp_high_color     = hcfg.crit_color

hcfg.volume_high_color       = hcfg.crit_color
hcfg.volume_mid_color        = hcfg.warn_color
hcfg.volume_mute_color       = '#5C5C5C'
hcfg.usb_card_color          = '#BA4100'

hcfg.battery_low_color       = hcfg.crit_color
hcfg.battery_charge_color    = '#7FAE5A'

-- additional conf.
hcfg.titlebars_enabled       = false

hcfg.nw_decimal_places       = 2

hcfg.bl_step                 = 7 --percent
hcfg.vol_step                = 2 --percent
hcfg.usb_step                = hcfg.vol_step
hcfg.amp_step                = 25 --percent

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
