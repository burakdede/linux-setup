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
  system
  dotfiles
  sdk
  git
  settings
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
        "sdk|$ROOT_DIR/sdk/sdk.sh|SDKMAN toolchain"
    )

    if [[ $INCLUDE_GIT -eq 1 ]]; then
        steps+=("git|$ROOT_DIR/git/git.sh|GitHub SSH setup")
    fi

    if [[ $INCLUDE_SETTINGS -eq 1 ]]; then
        steps+=("settings|$ROOT_DIR/utils/settings.sh|GNOME desktop settings")
    fi

    echo_header "Ubuntu developer machine bootstrap"
    log_info "Optional steps are disabled by default to keep the base bootstrap non-interactive."

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
