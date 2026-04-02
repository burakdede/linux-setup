-- WezTerm configuration
-- https://wezfurlong.org/wezterm/config/files.html
--
-- This file is installed to ~/.config/wezterm/wezterm.lua
-- Fill in your personal customisations below; the defaults listed here
-- are the bare minimum needed for things to work correctly.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ─── Shell ────────────────────────────────────────────────────────────────────
-- Use login shell if available; fall back to zsh.
local login_shell = os.getenv("SHELL") or "/bin/zsh"
config.default_prog = { login_shell, "-l" }

-- ─── Terminal colour support ──────────────────────────────────────────────────
-- Report full WezTerm capabilities so neovim and tmux render colours correctly.
config.term = "wezterm"
-- Avoid key-repeat/input issues observed on some GNOME/Wayland setups.
config.enable_kitty_keyboard = false

-- ─── Scrollback ───────────────────────────────────────────────────────────────
config.scrollback_lines = 10000

-- ─── Tab bar ──────────────────────────────────────────────────────────────────
config.hide_tab_bar_if_only_one_tab = true

-- ─── Font ─────────────────────────────────────────────────────────────────────
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 13.0

-- ─── Your customisations below ───────────────────────────────────────────────
-- Colour scheme:   config.color_scheme = "..."
-- Window padding:  config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
-- Key bindings:    config.keys = { ... }

return config
