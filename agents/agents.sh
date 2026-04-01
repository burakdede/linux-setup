#!/usr/bin/env bash
# Coding agent configuration — MCP servers for Claude Code and Codex

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../utils/utils.sh"

CLAUDE_JSON="$HOME/.claude.json"
CODEX_JSON="$HOME/.openai/mcp.json"

# Merge a single MCP server entry into a target JSON config file.
# Creates the file (and parent dirs) if it doesn't exist.
# $1 - target file path
# $2 - jq key path for the servers object  (e.g. ".mcpServers" or ".mcpServers")
# $3 - server name
# $4 - server config JSON object
_add_mcp_to_file() {
    local target="$1"
    local key_path="$2"
    local name="$3"
    local config="$4"

    mkdir -p "$(dirname "$target")"

    if [[ -f "$target" ]]; then
        local updated
        updated="$(jq --arg n "$name" --argjson c "$config" \
            "${key_path}"'[$n] = $c' "$target")"
        echo "$updated" > "$target"
    else
        jq -n --arg n "$name" --argjson c "$config" \
            "{mcpServers: {(\$n): \$c}}" > "$target"
    fi
}

add_mcp_claude() {
    local name="$1"
    local config="$2"
    _add_mcp_to_file "$CLAUDE_JSON" ".mcpServers" "$name" "$config"
    log_info "Claude Code MCP registered: $name"
}

add_mcp_codex() {
    local name="$1"
    local config="$2"
    _add_mcp_to_file "$CODEX_JSON" ".mcpServers" "$name" "$config"
    log_info "Codex MCP registered: $name"
}

add_mcp_all() {
    local name="$1"
    local config="$2"
    add_mcp_claude "$name" "$config"
    add_mcp_codex  "$name" "$config"
}

# Like add_mcp_all but never blocks the install — used for token-gated MCPs
# whose key may be absent. Logs a warning on failure instead of exiting.
try_add_mcp_all() {
    local name="$1"
    local config="$2"
    if ! (add_mcp_all "$name" "$config") 2>/dev/null; then
        log_warn "MCP '$name' could not be registered — skipping (fill in manually later)"
    fi
}

configure_mcps() {
    echo_header "MCP servers (Claude Code + Codex)"

    # ── No-auth MCPs — registered for both agents ──────────────────────────

    add_mcp_all "filesystem" "$(jq -n \
        --arg home "$HOME" \
        '{command:"npx",args:["-y","@modelcontextprotocol/server-filesystem",$home]}')"

    add_mcp_all "memory" \
        '{"command":"npx","args":["-y","@modelcontextprotocol/server-memory"]}'

    add_mcp_all "sequential-thinking" \
        '{"command":"npx","args":["-y","@modelcontextprotocol/server-sequential-thinking"]}'

    add_mcp_all "fetch" \
        '{"command":"npx","args":["-y","@modelcontextprotocol/server-fetch"]}'

    add_mcp_all "playwright" \
        '{"command":"npx","args":["-y","@playwright/mcp@latest"]}'

    # ── Token-gated MCPs ────────────────────────────────────────────────────

    # Try to pull Linear API key from LastPass if logged in
    local linear_key=""
    if command_exists lpass; then
        linear_key="$(lpass show --password "Linear API Key" 2>/dev/null || true)"
    fi

    local linear_config
    linear_config="$(jq -n \
        --arg key "$linear_key" \
        '{command:"npx",args:["-y","@linear/mcp-server"],env:{LINEAR_API_KEY:$key}}')"

    try_add_mcp_all "linear" "$linear_config"

    if [[ -z "$linear_key" ]]; then
        log_warn "Linear MCP: fill in LINEAR_API_KEY in $CLAUDE_JSON and $CODEX_JSON"
        log_warn "Get your key at: https://linear.app/settings/api"
    fi

    log_success "MCP configuration written to:"
    log_success "  $CLAUDE_JSON"
    log_success "  $CODEX_JSON"
}

configure_mcps
