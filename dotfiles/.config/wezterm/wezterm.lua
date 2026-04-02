-- WezTerm configuration
-- https://wezfurlong.org/wezterm/config/files.html
--
-- This file is installed to ~/.config/wezterm/wezterm.lua
-- Fill in your personal customisations below; the defaults listed here
-- are the bare minimum needed for things to work correctly.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ─── Shell ────────────────────────────────────────────────────────────────────
-- Use zsh (set as default shell by the shell step).
config.default_prog = { "/usr/bin/zsh", "-l" }

-- ─── Terminal colour support ──────────────────────────────────────────────────
-- Report full WezTerm capabilities so neovim and tmux render colours correctly.
config.term = "wezterm"

-- ─── Scrollback ───────────────────────────────────────────────────────────────
config.scrollback_lines = 10000

-- ─── Tab bar ──────────────────────────────────────────────────────────────────
config.hide_tab_bar_if_only_one_tab = true

-- ─── Your customisations below ───────────────────────────────────────────────
-- Colour scheme:   config.color_scheme = "..."
-- Font:            config.font = wezterm.font("JetBrainsMono Nerd Font")
-- Font size:       config.font_size = 13.0
-- Window padding:  config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
-- Key bindings:    config.keys = { ... }

return config
