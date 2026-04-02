-- WezTerm configuration
-- https://wezfurlong.org/wezterm/config/files.html
--
-- This file is installed to ~/.config/wezterm/wezterm.lua
-- Fill in your personal customisations below; the defaults listed here
-- provide a solid baseline and seamless integration with zsh, tmux, and neovim.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ─── Shell ────────────────────────────────────────────────────────────────────
-- Launch zsh as the default shell.
config.default_prog = { "/usr/bin/zsh", "-l" }

-- ─── Appearance ───────────────────────────────────────────────────────────────
-- Uncomment or replace with your preferred colour scheme.
-- A full list: https://wezfurlong.org/wezterm/colorschemes/index.html
--
-- config.color_scheme = "Catppuccin Mocha"
-- config.color_scheme = "Tokyo Night"
-- config.color_scheme = "nord"

-- config.font = wezterm.font("JetBrains Mono", { weight = "Regular" })
-- config.font_size = 13.0

-- ─── Terminal behaviour ───────────────────────────────────────────────────────
-- Report true 256-colour / true-colour support so that neovim and tmux render
-- colours correctly.
config.term = "wezterm"

-- Disable the title bar while keeping the window border for tiling WMs.
-- config.window_decorations = "RESIZE"

-- ─── Scrollback ───────────────────────────────────────────────────────────────
config.scrollback_lines = 10000

-- ─── Tab bar ──────────────────────────────────────────────────────────────────
config.hide_tab_bar_if_only_one_tab = true
-- config.use_fancy_tab_bar = false

-- ─── Key bindings ─────────────────────────────────────────────────────────────
-- Add your custom key bindings here.
-- config.keys = {}

-- ─── Mouse bindings ───────────────────────────────────────────────────────────
-- config.mouse_bindings = {}

-- ─── Padding ──────────────────────────────────────────────────────────────────
-- config.window_padding = { left = 4, right = 4, top = 4, bottom = 4 }

return config
