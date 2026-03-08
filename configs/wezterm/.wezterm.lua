local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Keep existing font and window configuration
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 11
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.show_tabs_in_tab_bar = true
config.tab_max_width = 60
config.tab_and_split_indices_are_zero_based = false

-- Tab bar styling
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_style = {
  new_tab = wezterm.format({
    { Background = { Color = '#000000' } },
    { Foreground = { Color = '#808080' } },
    { Text = ' + ' },
  }),
  new_tab_hover = wezterm.format({
    { Background = { Color = '#252525' } },
    { Foreground = { Color = '#FFFFFF' } },
    { Text = ' + ' },
  }),
}

config.keys = {
  {key="Enter", mods="SHIFT", action=wezterm.action{SendString="\x1b\r"}},
}

config.mux_enable_ssh_agent = false

return config
