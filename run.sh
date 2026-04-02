#!/usr/bin/env bash
# Ubuntu Developer Machine Setup Orchestration Script

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/utils/utils.sh"

trap 'handle_error $? $LINENO' ERR

INCLUDE_GIT=0
INCLUDE_SETTINGS=0
ONLY_STEPS=()

usage() {
    cat <<'EOF'
Usage: ./run.sh [options]

Options:
  --include-git       Run the interactive GitHub SSH setup step.
  --include-settings  Apply GNOME desktop preferences.
  --only STEP         Run only a single step. Repeatable.
  --help              Show this help text.

Valid STEP values:
  system          APT packages, Docker, runtimes (mise, Rust, Go, Python)
  dotfiles        Symlink config files into $HOME
  terminal        WezTerm  [depends: system]
  shell           Zsh      [depends: system]
  editor          Neovim   [depends: system]
  multiplexer     Tmux     [depends: system]
  sdk             SDKMAN toolchain (Java, Kotlin, …)  [depends: system]
  agents          Coding agent MCP configuration  [depends: system]
  git             GitHub SSH key setup (interactive)
  settings        GNOME desktop preferences (requires desktop session)

Step dependencies:
  - Run `system` first when bootstrapping a fresh machine; the other steps
    rely on packages (curl, jq, apt, mise) that system installs.
  - `editor` (jdtls / Java LSP) needs a JDK — run `sdk` first or install
    a JDK via another means before opening a Java file in Neovim.
  - `agents` needs Node (npm) — run `system` so mise installs Node LTS.
EOF
}

contains_step() {
    local wanted="$1"
    local step
    for step in "${ONLY_STEPS[@]}"; do
        [[ "$step" == "$wanted" ]] && return 0
    done
    return 1
}

should_run_step() {
    local step="$1"
    if [[ ${#ONLY_STEPS[@]} -eq 0 ]]; then
        return 0
    fi
    contains_step "$step"
}

# Emit a warning when a dependency step is not in the selected set.
check_step_deps() {
    local step="$1"
    shift
    local dep
    for dep in "$@"; do
        if [[ ${#ONLY_STEPS[@]} -gt 0 ]] && ! contains_step "$dep"; then
            log_warn "Step '$step' may depend on '$dep' which is not in the selected steps."
        fi
    done
}

run_script() {
    local step="$1"
    local script_path="$2"
    local description="$3"

    if [[ ! -f "$script_path" ]]; then
        log_warn "Skipping ${description}; script not found at ${script_path}."
        return 0
    fi

    echo_header "Starting: ${description}"
    bash "$script_path"
    log_success "Completed: ${description}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --include-git)
            INCLUDE_GIT=1
            ;;
        --include-settings)
            INCLUDE_SETTINGS=1
            ;;
        --only)
            shift
            if [[ $# -eq 0 ]]; then
                log_error "--only requires a step name."
                exit 1
            fi
            ONLY_STEPS+=("$1")
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
    shift
done

main() {
    check_root
    check_directory

    local step_name
    local -a steps=(
        "system|$ROOT_DIR/system/system.sh|System packages and developer tooling"
        "dotfiles|$ROOT_DIR/dotfiles/dotfiles.sh|Dotfiles"
        "terminal|$ROOT_DIR/terminal/terminal.sh|WezTerm terminal emulator"
        "shell|$ROOT_DIR/shell/shell.sh|Zsh shell"
        "editor|$ROOT_DIR/editor/editor.sh|Neovim editor"
        "multiplexer|$ROOT_DIR/multiplexer/multiplexer.sh|Tmux multiplexer"
        "sdk|$ROOT_DIR/sdk/sdk.sh|SDKMAN toolchain"
        "agents|$ROOT_DIR/agents/agents.sh|Coding agent MCP configuration"
    )

    if [[ $INCLUDE_GIT -eq 1 ]]; then
        steps+=("git|$ROOT_DIR/git/git.sh|GitHub SSH setup")
    fi

    if [[ $INCLUDE_SETTINGS -eq 1 ]]; then
        steps+=("settings|$ROOT_DIR/utils/settings.sh|GNOME desktop settings")
    fi

    echo_header "Ubuntu developer machine bootstrap"
    log_info "Optional steps are disabled by default to keep the base bootstrap non-interactive."

    # Warn about unmet dependencies when running with --only
    if [[ ${#ONLY_STEPS[@]} -gt 0 ]]; then
        for step_name in terminal shell editor multiplexer sdk agents; do
            if contains_step "$step_name"; then
                check_step_deps "$step_name" system
            fi
        done
        if contains_step editor; then
            check_step_deps "editor (Java LSP)" sdk
        fi
        if contains_step agents; then
            check_step_deps "agents (npm MCPs)" system
        fi
    fi

    local total=0
    local record
    for record in "${steps[@]}"; do
        IFS='|' read -r step_name _ _ <<< "$record"
        if should_run_step "$step_name"; then
            total=$((total + 1))
        fi
    done

    if [[ $total -eq 0 ]]; then
        log_warn "No steps selected."
        exit 0
    fi

    local current=0
    local script_path
    local description
    for record in "${steps[@]}"; do
        IFS='|' read -r step_name script_path description <<< "$record"
        if ! should_run_step "$step_name"; then
            continue
        fi

        current=$((current + 1))
        echo_header "Step ${current}/${total}: ${description}"
        run_script "$step_name" "$script_path" "$description"
    done

    echo_header "Bootstrap complete"
}

main
