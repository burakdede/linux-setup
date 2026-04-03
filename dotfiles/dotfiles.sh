#!/usr/bin/env bash
# Dotfiles installation script.
#
# Creates symlinks from $HOME (and $HOME/.config) to the versioned dotfiles in
# this repository.  Symlinks mean edits in-place are immediately reflected in
# the repo — no copy/sync step needed.
#
# Existing targets are backed up before being replaced.
# The script is idempotent: re-running it is safe.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

BACKUP_ROOT="$HOME/.local/state/linux-setup/dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

# ── Helpers ───────────────────────────────────────────────────────────────────

backup_target() {
    local target="$1"
    local relative="${target#"$HOME"/}"
    local backup_path="$BACKUP_ROOT/$relative"

    if [[ ! -e "$target" && ! -L "$target" ]]; then
        return 0
    fi

    # Don't back up a symlink that already points to our repo
    if [[ -L "$target" ]] && \
       [[ "$(readlink -f "$target" 2>/dev/null)" == "$SCRIPT_DIR"* ]]; then
        return 0
    fi

    mkdir -p "$(dirname "$backup_path")"
    cp -a "$target" "$backup_path"
}

link_path() {
    local source_path="$1"   # absolute path inside dotfiles/
    local target_path="$2"   # absolute path in $HOME

    backup_target "$target_path"
    mkdir -p "$(dirname "$target_path")"

    # Remove whatever was there (file, dir, or stale symlink)
    rm -rf "$target_path"
    ln -sf "$source_path" "$target_path"

    log_success "Linked $(basename "$target_path")"
}

# ── .config sub-directories ───────────────────────────────────────────────────
# We never symlink ~/.config itself (other tools own entries there).
# Instead we symlink each managed sub-directory individually.

install_config_entries() {
    local config_source="$SCRIPT_DIR/.config"
    local config_target="$HOME/.config"

    [[ -d "$config_source" ]] || return 0

    mkdir -p "$config_target"

    shopt -s dotglob nullglob
    local item
    for item in "$config_source"/*; do
        local name
        name="$(basename "$item")"
        link_path "$item" "$config_target/$name"
    done
    shopt -u dotglob nullglob
}

# ── Top-level dotfiles ────────────────────────────────────────────────────────

install_home_dotfiles() {
    shopt -s dotglob nullglob
    local path
    for path in "$SCRIPT_DIR"/*; do
        local name
        name="$(basename "$path")"

        # Skip the installer itself and the .config directory
        [[ "$name" == "dotfiles.sh" ]] && continue
        [[ "$name" == ".config"    ]] && continue

        link_path "$path" "$HOME/$name"
    done
    shopt -u dotglob nullglob
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    echo_header "Dotfiles"
    mkdir -p "$BACKUP_ROOT"

    install_home_dotfiles
    install_config_entries

    # .gitconfig sets init.templateDir = ~/.git_template; create the directory
    # so git doesn't emit "warning: templates not found" on every repo operation.
    mkdir -p "$HOME/.git_template"
    log_success "Created ~/.git_template (required by init.templateDir in .gitconfig)"

    log_info "Backups (if any) stored in $BACKUP_ROOT"
}

main
