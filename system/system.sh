#!/usr/bin/env bash
# System package and CLI bootstrap for Ubuntu.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

APT_PACKAGES_FILE="$SCRIPT_DIR/apt-packages.txt"
SNAP_PACKAGES_FILE="$SCRIPT_DIR/snap-packages.txt"
NPM_PACKAGES_FILE="$SCRIPT_DIR/npm-packages.txt"
UV_TOOLS_FILE="$SCRIPT_DIR/uv-tools.txt"
GITHUB_TOOLS_FILE="$SCRIPT_DIR/github-tools.txt"
MISE_BIN="$HOME/.local/bin/mise"

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

ensure_core_packages() {
    sudo_run apt-get update
    sudo_run apt-get install -y --no-install-recommends \
        ca-certificates curl gpg jq lsb-release software-properties-common wget
}

upgrade_base_system() {
    echo_header "System updates"
    sudo_run apt-get update
    sudo_run apt-get upgrade -y
    sudo_run apt-get autoremove -y
}

install_apt_packages() {
    echo_header "APT packages"

    if [[ ! -f "$APT_PACKAGES_FILE" ]]; then
        log_warn "Missing ${APT_PACKAGES_FILE}; skipping APT package installation."
        return 0
    fi

    mapfile -t packages < <(read_list_file "$APT_PACKAGES_FILE")
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_info "No APT packages declared."
        return 0
    fi

    log_info "Installing ${#packages[@]} APT packages."
    sudo_run apt-get install -y --no-install-recommends "${packages[@]}"
}

ensure_command_symlink() {
    local expected_name="$1"
    local source_command="$2"
    local source_path

    if command_exists "$expected_name"; then
        return 0
    fi

    if ! source_path="$(command -v "$source_command")"; then
        log_warn "Cannot create ${expected_name}; ${source_command} is not installed."
        return 0
    fi

    sudo_run ln -sf "$source_path" "/usr/local/bin/$expected_name"
}

ensure_agent_command_names() {
    echo_header "Command compatibility"
    ensure_command_symlink fd fdfind
    ensure_command_symlink bat batcat
}

install_snap_packages() {
    echo_header "Snap packages"

    if [[ ! -f "$SNAP_PACKAGES_FILE" ]]; then
        log_warn "Missing ${SNAP_PACKAGES_FILE}; skipping Snap packages."
        return 0
    fi

    local line package_name channel mode
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(trim "$line")"
        [[ -z "$line" ]] && continue

        package_name=""
        channel=""
        mode=""
        read -r package_name channel mode <<< "$line"

        if snap list "$package_name" >/dev/null 2>&1; then
            log_info "Snap package already installed: $package_name"
            continue
        fi

        local args=("snap" "install" "$package_name")
        [[ -n "$channel" && "$channel" != "-" ]] && args+=("--channel=$channel")
        [[ "$mode" == "classic" ]] && args+=("--classic")

        sudo_run "${args[@]}"
    done < "$SNAP_PACKAGES_FILE"
}

setup_vscode_repo() {
    if command_exists code; then
        log_info "VS Code is already installed."
        return 0
    fi

    echo_header "VS Code"
    sudo_run mkdir -p /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /etc/apt/keyrings/vscode.gpg
    printf 'deb [arch=amd64 signed-by=/etc/apt/keyrings/vscode.gpg] https://packages.microsoft.com/repos/code stable main\n' | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    sudo_run chmod 644 /etc/apt/keyrings/vscode.gpg
    sudo_run apt-get update
    sudo_run apt-get install -y code
}

install_vscode_extensions() {
    local extensions_file="$SCRIPT_DIR/vscode-extensions.txt"

    echo_header "VS Code extensions"
    if ! command_exists code; then
        log_warn "Skipping VS Code extensions; code command is unavailable."
        return 0
    fi

    if [[ ! -f "$extensions_file" ]]; then
        log_warn "Missing ${extensions_file}; skipping VS Code extensions."
        return 0
    fi

    local extension
    while IFS= read -r extension || [[ -n "$extension" ]]; do
        extension="${extension%%#*}"
        extension="$(trim "$extension")"
        [[ -z "$extension" ]] && continue

        if code --list-extensions | grep -Fxq "$extension"; then
            log_info "VS Code extension already installed: $extension"
            continue
        fi

        log_info "Installing VS Code extension: $extension"
        code --install-extension "$extension" --force
    done < "$extensions_file"
}

setup_google_chrome_repo() {
    if command_exists google-chrome; then
        log_info "Google Chrome is already installed."
        return 0
    fi

    echo_header "Google Chrome"
    sudo_run mkdir -p /etc/apt/keyrings
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg
    printf 'deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main\n' | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
    sudo_run chmod 644 /etc/apt/keyrings/google-chrome.gpg
    sudo_run apt-get update
    sudo_run apt-get install -y google-chrome-stable
}

setup_docker_repo() {
    echo_header "Docker CLI and Compose"

    if dpkg -s docker-ce-cli >/dev/null 2>&1 && dpkg -s docker-compose-plugin >/dev/null 2>&1; then
        log_info "Docker CLI and Compose plugin are already installed."
        return 0
    fi

    sudo_run mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo_run chmod a+r /etc/apt/keyrings/docker.gpg

    local codename
    # shellcheck source=/dev/null
    codename="$(. /etc/os-release && printf '%s' "$VERSION_CODENAME")"
    printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu %s stable\n' \
        "$(dpkg --print-architecture)" "$codename" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo_run apt-get update
    sudo_run apt-get install -y docker-ce-cli docker-buildx-plugin docker-compose-plugin
}

download_latest_release_asset() {
    local repo="$1"
    local asset_pattern="$2"
    local metadata_file="$3"

    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" -o "$metadata_file"
    jq -r --arg pattern "$asset_pattern" \
        '.assets[] | select(.name | test($pattern)) | .browser_download_url' \
        "$metadata_file" | head -n1
}

install_github_release_tools() {
    echo_header "GitHub release tools"

    if [[ ! -f "$GITHUB_TOOLS_FILE" ]]; then
        log_warn "Missing ${GITHUB_TOOLS_FILE}; skipping GitHub release tools."
        return 0
    fi

    local line command_name repo asset_pattern mode binary_name
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="$(trim "$line")"
        [[ -z "$line" ]] && continue

        IFS='|' read -r command_name repo asset_pattern mode binary_name <<< "$line"
        binary_name="${binary_name:-$command_name}"

        if command_exists "$command_name"; then
            log_info "Tool already installed: $command_name"
            continue
        fi

        local temp_dir metadata_file download_url archive_path extracted_path
        temp_dir="$(mktemp -d)"
        metadata_file="$temp_dir/release.json"
        download_url="$(download_latest_release_asset "$repo" "$asset_pattern" "$metadata_file")"

        if [[ -z "$download_url" || "$download_url" == "null" ]]; then
            log_warn "Could not find a matching release asset for $command_name from $repo."
            rm -rf "$temp_dir"
            continue
        fi

        case "$mode" in
            raw)
                archive_path="$temp_dir/$binary_name"
                curl -fsSL "$download_url" -o "$archive_path"
                sudo_run install -m 0755 "$archive_path" "/usr/local/bin/$command_name"
                ;;
            tar.gz)
                archive_path="$temp_dir/archive.tar.gz"
                curl -fsSL "$download_url" -o "$archive_path"
                tar -xzf "$archive_path" -C "$temp_dir"
                extracted_path="$(find "$temp_dir" -type f -name "$binary_name" | head -n1)"
                if [[ -z "$extracted_path" ]]; then
                    log_warn "Downloaded $command_name but could not locate $binary_name in the archive."
                    rm -rf "$temp_dir"
                    continue
                fi
                sudo_run install -m 0755 "$extracted_path" "/usr/local/bin/$command_name"
                ;;
            *)
                log_warn "Unsupported install mode '$mode' for $command_name."
                rm -rf "$temp_dir"
                continue
                ;;
        esac

        rm -rf "$temp_dir"
    done < "$GITHUB_TOOLS_FILE"
}

install_uv() {
    echo_header "uv"

    if command_exists uv; then
        log_info "uv is already installed."
        return 0
    fi

    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
}

install_uv_tools() {
    echo_header "uv tools"

    if [[ ! -f "$UV_TOOLS_FILE" ]]; then
        log_warn "Missing ${UV_TOOLS_FILE}; skipping uv tools."
        return 0
    fi

    export PATH="$HOME/.local/bin:$PATH"

    local package_name
    while IFS= read -r package_name || [[ -n "$package_name" ]]; do
        package_name="${package_name%%#*}"
        package_name="$(trim "$package_name")"
        [[ -z "$package_name" ]] && continue

        log_info "Installing uv tool: $package_name"
        uv tool install --quiet "$package_name" || uv tool upgrade "$package_name"
    done < "$UV_TOOLS_FILE"
}

install_claude_code() {
    echo_header "Claude Code"

    if command_exists claude; then
        log_info "Claude Code is already installed."
        return 0
    fi

    curl -fsSL https://claude.ai/install.sh | bash
}

install_mise() {
    echo_header "mise"

    if [[ ! -x "$MISE_BIN" ]]; then
        curl -fsSL https://mise.run | sh
    fi

    local mise_activation_line
    # shellcheck disable=SC2016
    mise_activation_line='eval "$("$HOME/.local/bin/mise" activate bash)"'
    ensure_line_in_file "$mise_activation_line" "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
    eval "$("$MISE_BIN" activate bash)"
}

install_node_runtime() {
    echo_header "Node.js via mise"
    install_mise
    "$MISE_BIN" use --global node@lts
}

install_npm_clis() {
    echo_header "Node-based tooling"

    if [[ ! -f "$NPM_PACKAGES_FILE" ]]; then
        log_warn "Missing ${NPM_PACKAGES_FILE}; skipping npm CLIs."
        return 0
    fi

    install_node_runtime

    local package_name
    while IFS= read -r package_name || [[ -n "$package_name" ]]; do
        package_name="${package_name%%#*}"
        package_name="$(trim "$package_name")"
        [[ -z "$package_name" ]] && continue

        log_info "Installing npm package: $package_name"
        "$MISE_BIN" exec node@lts -- npm install --global "$package_name"
    done < "$NPM_PACKAGES_FILE"
}

main() {
    check_root
    ensure_sudo

    ensure_core_packages
    upgrade_base_system
    install_apt_packages
    ensure_agent_command_names

    if ! should_skip_step DOCKER; then
        setup_docker_repo
    fi

    if ! should_skip_step SNAPS; then
        install_snap_packages
    fi

    if ! should_skip_step VSCODE; then
        setup_vscode_repo
    fi

    if ! should_skip_step VSCODE_EXTENSIONS; then
        install_vscode_extensions
    fi

    if ! should_skip_step CHROME; then
        setup_google_chrome_repo
    fi

    if ! should_skip_step GITHUB_RELEASE_TOOLS; then
        install_github_release_tools
    fi

    if ! should_skip_step UV; then
        install_uv
        install_uv_tools
    fi

    if ! should_skip_step CLAUDE; then
        install_claude_code
    fi

    if ! should_skip_step NPM_TOOLS; then
        install_npm_clis
    fi

    echo_header "System bootstrap complete"
    log_success "Base packages, agent-oriented CLIs, and runtime managers are installed."
}

main
