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
-- xterm-256color is the safest default: wezterm terminfo is not bundled with
-- the apt package on Ubuntu, so TERM=wezterm causes ncurses fallback and garbled
-- Ctrl sequences. Use wezterm-256color only when the terminfo is confirmed present.
config.term = "xterm-256color"

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
-- Disable conflicting defaults and use platform-native modifier keys:
--   macOS  → CMD        (Cmd+C/V/T/W — standard Mac conventions)
--   Linux  → CTRL+SHIFT (Ctrl+Shift+C/V/T/W — standard Linux conventions)
config.disable_default_key_bindings = true

local act = wezterm.action
local is_mac = wezterm.target_triple:find("darwin") ~= nil
local mod = is_mac and "SUPER" or "SHIFT|CTRL"

config.keys = {
    -- ── Clipboard ──────────────────────────────────────────────────────────
    { key = "c", mods = mod,            action = act.CopyTo("Clipboard") },
    { key = "v", mods = mod,            action = act.PasteFrom("Clipboard") },

    -- ── Tabs ───────────────────────────────────────────────────────────────
    { key = "t", mods = mod,            action = act.SpawnTab("CurrentPaneDomain") },
    { key = "w", mods = mod,            action = act.CloseCurrentTab({ confirm = true }) },
    { key = "Tab", mods = "CTRL",       action = act.ActivateTabRelative(1) },
    { key = "Tab", mods = "SHIFT|CTRL", action = act.ActivateTabRelative(-1) },

    -- ── Panes ──────────────────────────────────────────────────────────────
    { key = "e", mods = mod,            action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "o", mods = mod,            action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
    { key = "z", mods = mod,            action = act.TogglePaneZoomState },

    -- ── Font size ──────────────────────────────────────────────────────────
    { key = "=", mods = is_mac and "SUPER" or "CTRL", action = act.IncreaseFontSize },
    { key = "-", mods = is_mac and "SUPER" or "CTRL", action = act.DecreaseFontSize },
    { key = "0", mods = is_mac and "SUPER" or "CTRL", action = act.ResetFontSize },

    -- ── Window ─────────────────────────────────────────────────────────────
    { key = "n", mods = mod,            action = act.SpawnWindow },
    { key = "F11",                      action = act.ToggleFullScreen },

    -- ── Copy mode (vim-like keyboard text selection) ───────────────────────
    { key = "x", mods = mod,            action = act.ActivateCopyMode },

    -- ── Search ─────────────────────────────────────────────────────────────
    { key = "f", mods = mod,            action = act.Search("CurrentSelectionOrEmptyString") },

    -- ── Scrollback ─────────────────────────────────────────────────────────
    { key = "PageUp",   mods = "SHIFT", action = act.ScrollByPage(-1) },
    { key = "PageDown", mods = "SHIFT", action = act.ScrollByPage(1) },
}

-- ─── Mouse bindings ──────────────────────────────────────────────────────────
config.mouse_bindings = {
    -- Right-click pastes from clipboard (standard terminal behaviour on Linux).
    -- If text is selected, right-click copies it instead.
    {
        event  = { Down = { streak = 1, button = "Right" } },
        mods   = "NONE",
        action = wezterm.action_callback(function(window, pane)
            local has_selection = window:get_selection_text_for_pane(pane) ~= ""
            if has_selection then
                window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
                window:perform_action(act.ClearSelection, pane)
            else
                window:perform_action(act.PasteFrom("Clipboard"), pane)
            end
        end),
    },
}

-- ─── Your customisations below ───────────────────────────────────────────────
-- Colour scheme:   config.color_scheme = "..."
-- Window padding:  config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }

return config
