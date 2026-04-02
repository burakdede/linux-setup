#!/usr/bin/env bash
# Neovim installation and system integration.
#
# Downloads the latest stable Neovim AppImage from GitHub (neovim/neovim),
# installs it to /usr/local/bin/nvim, and registers it with update-alternatives
# so that `vim`, `vi`, and `editor` all resolve to nvim.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

NVIM_INSTALL_DIR="/usr/local"
NVIM_BIN="$NVIM_INSTALL_DIR/bin/nvim"

flag_enabled() {
    local value="${1:-0}"
    case "$value" in
        1|true|TRUE|yes|YES|on|ON) return 0 ;;
        *) return 1 ;;
    esac
}

should_skip_step() {
    local step_name="$1"
    local var_name="LINUX_SETUP_SKIP_${step_name}"
    flag_enabled "${!var_name:-0}"
}

upgrade_enabled() {
    flag_enabled "${LINUX_SETUP_UPGRADE:-0}"
}

install_neovim() {
    echo_header "Neovim"

    if command_exists nvim && ! upgrade_enabled; then
        log_info "Neovim is already installed. (set LINUX_SETUP_UPGRADE=1 to upgrade)"
        return 0
    fi

    # Install build dependencies needed by some Neovim plugins (tree-sitter parsers, etc.)
    log_info "Installing Neovim build dependencies..."
    sudo_run apt-get install -y --no-install-recommends \
        build-essential cmake gettext ninja-build unzip curl

    local temp_dir metadata_file download_url archive_path
    temp_dir="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$temp_dir'" RETURN
    metadata_file="$temp_dir/release.json"

    log_info "Fetching latest stable Neovim release metadata..."
    curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" \
        -o "$metadata_file"

    if jq -e '.message' "$metadata_file" &>/dev/null; then
        log_warn "GitHub API error: $(jq -r '.message' "$metadata_file"). Skipping Neovim."
        return 0
    fi

    # Prefer pre-built linux-x86_64 tarball; it unpacks to a self-contained tree.
    download_url="$(jq -r \
        '.assets[] | select(.name | test("nvim-linux-x86_64\\.tar\\.gz$")) | .browser_download_url' \
        "$metadata_file" | head -n1)"

    if [[ -z "$download_url" || "$download_url" == "null" ]]; then
        log_warn "Could not find nvim-linux-x86_64.tar.gz release asset. Skipping."
        return 0
    fi

    log_info "Downloading Neovim from: $download_url"
    archive_path="$temp_dir/nvim.tar.gz"
    curl -fsSL "$download_url" -o "$archive_path"

    log_info "Extracting and installing Neovim to $NVIM_INSTALL_DIR ..."
    tar -xzf "$archive_path" -C "$temp_dir"
    local extracted_dir
    extracted_dir="$(find "$temp_dir" -maxdepth 1 -type d -name 'nvim-*' | head -n1)"

    if [[ -z "$extracted_dir" ]]; then
        log_warn "Could not find extracted Neovim directory. Skipping."
        return 0
    fi

    # Copy bin, lib, share into /usr/local (merges cleanly)
    sudo_run cp -rf "$extracted_dir/bin/."   "$NVIM_INSTALL_DIR/bin/"
    sudo_run cp -rf "$extracted_dir/lib/."   "$NVIM_INSTALL_DIR/lib/"   2>/dev/null || true
    sudo_run cp -rf "$extracted_dir/share/." "$NVIM_INSTALL_DIR/share/" 2>/dev/null || true
    sudo_run chmod 0755 "$NVIM_BIN"

    rm -rf "$temp_dir"
    log_success "Neovim installed to $NVIM_BIN"
}

register_alternatives() {
    if [[ ! -x "$NVIM_BIN" ]]; then
        log_warn "$NVIM_BIN not found; skipping update-alternatives registration."
        return 0
    fi

    log_info "Registering Neovim with update-alternatives..."

    # vim
    sudo_run update-alternatives --install /usr/bin/vim   vim   "$NVIM_BIN" 60
    sudo_run update-alternatives --set            vim           "$NVIM_BIN"

    # vi
    sudo_run update-alternatives --install /usr/bin/vi    vi    "$NVIM_BIN" 60
    sudo_run update-alternatives --set            vi            "$NVIM_BIN"

    # editor (used by git, crontab, etc.)
    sudo_run update-alternatives --install /usr/bin/editor editor "$NVIM_BIN" 60
    sudo_run update-alternatives --set              editor         "$NVIM_BIN"

    log_success "vim, vi, and editor now resolve to nvim."
}

main() {
    check_root
    ensure_sudo
    export PATH="$HOME/.local/bin:$PATH"

    if ! should_skip_step NEOVIM; then
        install_neovim
        register_alternatives
    else
        log_info "Skipping Neovim (LINUX_SETUP_SKIP_NEOVIM is set)."
    fi

    echo_header "Editor setup complete"
    log_success "Neovim is ready. Config: ~/.config/nvim/"
    log_info "On first launch, lazy.nvim will bootstrap itself and install plugins."
}

main
