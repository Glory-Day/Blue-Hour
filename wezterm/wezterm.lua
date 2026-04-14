local wezterm = require 'wezterm'
local config = {}

config.enable_wayland = true

config.font = wezterm.font('JetBrains Mono')
config.font_size = 13.0

config.colors = {
    foreground = '#E6EDF3',
    background = '#0D1117',

    cursor_bg = '#79C0FF',
    cursor_fg = '#0D1117',
    cursor_border = '#79C0FF',

    selection_fg = '#E6EDF3',
    selection_bg = '#051D4D',

    scrollbar_thumb = '#30363D',
    split = '#30363D',

    ansi = {
        '#21262D', '#FF7B72', '#3FB950', '#F0C944',
        '#79C0FF', '#D2A8FF', '#39C5CF', '#8D96A0',
    },

    brights = {
        '#30363D', '#FFA198', '#56D364', '#F0C944',
        '#79C0FF', '#D2A8FF', '#39C5CF', '#E6EDF3',
    },
}

config.window_background_opacity = 0.95
config.window_padding = {
    left = 12,
    right = 12,
    top = 8,
    bottom = 8,
}

config.hide_tab_bar_if_only_one_tab = true


return config
