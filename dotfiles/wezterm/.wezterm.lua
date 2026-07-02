local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback { 'JetBrainsMono Nerd Font', 'JetBrains Mono' }
config.font_size = 13
config.color_scheme = 'Jetbrains Darcula'
config.enable_scroll_bar = true
config.initial_cols = 120
config.initial_rows = 28

return config
