# ~/.zprofile — sourced for login shells (SSH, display managers, su -l).
#
# Login shells source .zprofile but NOT .zshrc, so PATH additions and
# EDITOR must be available here too.  We simply pull in .zshenv which
# already has everything we need — no duplication required.

# shellcheck shell=bash
[[ -f "$HOME/.zshenv" ]] && source "$HOME/.zshenv"

# mise: activate in login shells (covers SSH sessions, cron, display managers)
if [[ -x "$HOME/.local/bin/mise" ]]; then
    eval "$("$HOME/.local/bin/mise" activate zsh --shims)"
fi
