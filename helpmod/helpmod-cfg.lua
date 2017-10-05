local hcfg = {}

hcfg.net_devices = { "eno1", "wlp3s0" }

hcfg.warn_color              = '#FECA00'
hcfg.crit_color              = '#FF0000'

hcfg.net_download_color      = '#CC9933'
hcfg.net_upload_color        = '#7F9F7F'
hcfg.klimit                  = 1024

hcfg.cpu_temp_low_color      = '#7FAE5A'
hcfg.cpu_temp_medium_color   = hcfg.warn_color
hcfg.cpu_temp_high_color     = hcfg.crit_color
hcfg.cpu_temp_high           = 85
hcfg.cpu_temp_mid            = 55

hcfg.volume_high             = 65
hcfg.volume_mid              = 40
hcfg.volume_high_color       = hcfg.crit_color
hcfg.volume_mid_color        = hcfg.warn_color
hcfg.volume_mute_color       = '#5C5C5C'

hcfg.battery_low             = 15
hcfg.battery_low_color       = hcfg.crit_color
hcfg.battery_charge_color    = '#7FAE5A'

hcfg.spacetxt   = ' '
hcfg.spacetxt2  = '  '
hcfg.spacetxt3  = '   '
hcfg.separtxt   = ' | '

return hcfg
