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
-- Use xterm-256color: the "wezterm" terminfo is not shipped by the apt package
-- so advertising TERM=wezterm causes the shell to fall back anyway, creating a
-- mismatch that garbles Ctrl key sequences (readline Ctrl+W, Ctrl+R, etc.).
config.term = "xterm-256color"
-- Avoid key-repeat/input issues observed on some GNOME/Wayland setups.
config.enable_kitty_keyboard = false
-- Stability-first defaults on Linux desktop stacks:
-- - disable native Wayland backend to avoid input duplication issues
-- - disable IME path unless explicitly needed
config.enable_wayland = false
config.use_ime = false

-- ─── Scrollback ───────────────────────────────────────────────────────────────
config.scrollback_lines = 10000

-- ─── Tab bar ──────────────────────────────────────────────────────────────────
config.hide_tab_bar_if_only_one_tab = true

-- ─── Font ─────────────────────────────────────────────────────────────────────
config.font = wezterm.font("JetBrainsMono Nerd Font")
config.font_size = 13.0

-- ─── Key bindings ─────────────────────────────────────────────────────────────
-- WezTerm's defaults intercept many Ctrl+letter combos that readline/zsh rely
-- on (Ctrl+R history search, Ctrl+W kill-word, Ctrl+K kill-line, etc.).
-- Disable conflicting defaults and remap WezTerm actions to Super/Ctrl+Shift.
config.disable_default_key_bindings = true

local act = wezterm.action
config.keys = {
    -- ── Clipboard ──────────────────────────────────────────────────────────
    { key = "c", mods = "SUPER",      action = act.CopyTo("Clipboard") },
    { key = "v", mods = "SUPER",      action = act.PasteFrom("Clipboard") },

    -- ── Tabs ───────────────────────────────────────────────────────────────
    { key = "t", mods = "SUPER",      action = act.SpawnTab("CurrentPaneDomain") },
    { key = "w", mods = "SUPER",      action = act.CloseCurrentTab({ confirm = true }) },
    { key = "Tab", mods = "CTRL",     action = act.ActivateTabRelative(1) },
    { key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },

    -- ── Panes ──────────────────────────────────────────────────────────────
    { key = "d", mods = "SUPER",      action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "d", mods = "SHIFT|SUPER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "z", mods = "SUPER",      action = act.TogglePaneZoomState },

    -- ── Font size ──────────────────────────────────────────────────────────
    { key = "=", mods = "SUPER",      action = act.IncreaseFontSize },
    { key = "-", mods = "SUPER",      action = act.DecreaseFontSize },
    { key = "0", mods = "SUPER",      action = act.ResetFontSize },

    -- ── Window ─────────────────────────────────────────────────────────────
    { key = "n", mods = "SUPER",      action = act.SpawnWindow },
    { key = "m", mods = "SUPER",      action = act.Hide },
    { key = "Enter", mods = "ALT",    action = act.ToggleFullScreen },

    -- ── Search / overlay ───────────────────────────────────────────────────
    { key = "f", mods = "SUPER",      action = act.Search("CurrentSelectionOrEmptyString") },
    { key = "l", mods = "SUPER",      action = act.ShowDebugOverlay },

    -- ── Scrollback ─────────────────────────────────────────────────────────
    { key = "PageUp",   mods = "SHIFT", action = act.ScrollByPage(-1) },
    { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
}

-- ─── Your customisations below ───────────────────────────────────────────────
-- Colour scheme:   config.color_scheme = "..."
-- Window padding:  config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }

return config
