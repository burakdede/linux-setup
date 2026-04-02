# ~/.zshrc — interactive zsh configuration.
#
# This file is sourced for interactive shells only.
# Fill in the sections below with your personal customisations.

# ─── mise runtime activation ──────────────────────────────────────────────────
# Activates mise-managed runtimes (Node, Go, Python, …) in interactive shells.
# This line is also appended automatically by shell/shell.sh.
if [[ -x "$HOME/.local/bin/mise" ]]; then
    eval "$("$HOME/.local/bin/mise" activate zsh)"
fi

# ─── Completion ───────────────────────────────────────────────────────────────
autoload -Uz compinit && compinit

# ─── History ──────────────────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS   # no duplicate entries
setopt HIST_IGNORE_SPACE      # skip commands starting with a space
setopt SHARE_HISTORY          # share history across sessions

# ─── Navigation ───────────────────────────────────────────────────────────────
setopt AUTO_CD                # type a directory name to cd into it

# ─── Key bindings ─────────────────────────────────────────────────────────────
bindkey -e                    # emacs key bindings (change to -v for vi mode)

# ─── Prompt ───────────────────────────────────────────────────────────────────
# Replace with your preferred theme (starship, powerlevel10k, pure, …)
autoload -Uz promptinit && promptinit
# prompt pure            # uncomment after installing pure
# eval "$(starship init zsh)"   # uncomment after installing starship

# Simple fallback prompt
PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f %# '

# ─── Aliases ──────────────────────────────────────────────────────────────────
# Source shared aliases if present.
[[ -f "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"

# Modern replacements (installed by system.sh)
if command -v eza &>/dev/null; then
    alias ls='eza --group-directories-first'
    alias ll='eza -lah --group-directories-first'
    alias lt='eza --tree --level=2'
fi
command -v bat  &>/dev/null && alias cat='bat --paging=never'
command -v rg   &>/dev/null && alias grep='rg'
command -v fd   &>/dev/null && alias find='fd'

# Editor shortcuts
alias vi='nvim'
alias vim='nvim'

# ─── fzf ──────────────────────────────────────────────────────────────────────
# Enable fzf key bindings and fuzzy completion if installed.
if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
    source /usr/share/doc/fzf/examples/completion.zsh
fi

# ─── tmux auto-attach ─────────────────────────────────────────────────────────
# Uncomment to automatically attach to (or start) a tmux session when opening
# a terminal that is not already inside tmux.
#
# if command -v tmux &>/dev/null && [[ -z "$TMUX" ]] && [[ "$TERM_PROGRAM" != "vscode" ]]; then
#     tmux attach-session -t default 2>/dev/null || tmux new-session -s default
# fi

# ─── Local overrides ──────────────────────────────────────────────────────────
# Machine-specific settings that should not be committed to version control.
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
