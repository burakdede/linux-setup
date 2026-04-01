# Ubuntu Developer Machine Setup

This repository bootstraps a fresh Ubuntu machine for development work with a bias toward maintainable, repeatable setup and strong support for terminal-first coding agents.

The default path installs:
- `lastpass-cli` as the first step (bootstrap dependency for secrets)
- core agent-oriented Ubuntu packages from `apt`
- command compatibility symlinks for `fd` and `bat`
- Google Chrome from its official repository
- Docker CLI and Compose plugin from Docker's official repository
- GitHub-release binaries for `yq`, `eza`, `sd`, and `scc`
- `uv` tools: `pre-commit`, `ruff`, `yamllint`
- `mise` as the runtime manager, with Node LTS, Go, Python, and Rust
- terminal coding agents: Codex, Claude Code, Gemini CLI, plus `eslint` and `prettier`
- firewall baseline: `ufw` (deny incoming, allow outgoing, SSH allowed), `fail2ban`
- system snapshots: `timeshift`
- MCP servers for Claude Code and Codex: filesystem, memory, fetch, sequential-thinking, playwright, Linear, Notion, Miro
- personal dotfiles

Interactive or highly personal steps are opt-in:
- GitHub SSH setup (prompts for git name + email): `./run.sh --include-git`
- GNOME desktop customization: `./run.sh --include-settings`

## Quick Start

1. Install Git:
   ```bash
   sudo apt update
   sudo apt install -y git
   ```
2. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/linux-setup
   cd linux-setup
   ```
3. Run the base bootstrap:
   ```bash
   ./run.sh
   ```

After the system step completes, log in to LastPass to allow future runs to auto-populate API keys:
```bash
lpass login <your-email>
```

## What Is Considered Essential

This repo treats the following categories as the base layer for coding agents:
- search and navigation: `rg`, `fd`, `tree`, `fzf`, `eza`
- file inspection and structured parsing: `bat`, `jq`, `yq`
- safer text transforms and repo understanding: `sd`, `scc`
- quality gates: `shellcheck`, `pre-commit`, `ruff`, `yamllint`, `eslint`, `prettier`
- agent CLIs: `codex`, `claude`, `gemini`
- runtime management: `mise` (Node LTS, Go latest, Python latest), `rustup`

That keeps the machine optimized for token-efficient codebase work without pulling in every situational devops tool by default.

## Manifests

The bootstrap is organized around manifests so package decisions stay in data instead of shell code:
- `system/apt-packages.txt`
- `system/snap-packages.txt`
- `system/github-tools.txt`
- `system/npm-packages.txt`
- `system/uv-tools.txt`
- `sdk/packages.txt`

## Running Specific Parts

Run only one module:

```bash
./run.sh --only system
./run.sh --only dotfiles
./run.sh --only sdk
./run.sh --only agents
```

Include optional modules:

```bash
./run.sh --include-git --include-settings
```

## MCP Servers

The `agents` step writes MCP configuration to `~/.claude.json` (Claude Code) and `~/.openai/mcp.json` (Codex).

Token-gated MCPs (Linear, Notion, Miro) are skipped gracefully if no key is found — they never block installation. To auto-populate keys, store them in LastPass before running:

| MCP | LastPass entry | Where to get the key |
|-----|---------------|----------------------|
| Linear | `Linear API Key` | https://linear.app/settings/api |
| Notion | `Notion API Key` | https://www.notion.so/profile/integrations |
| Miro | `Miro API Key` | https://miro.com/app/settings/user-profile/apps |

Or fill them in manually after bootstrap:
```bash
# Example for Claude Code
jq '.mcpServers.linear.env.LINEAR_API_KEY = "your-key"' ~/.claude.json | sponge ~/.claude.json
```

## Local And PR Gates

Install the repository-managed git hooks once:

```bash
bash scripts/install-hooks.sh
```

After that:
- `pre-commit` runs `bash scripts/test.sh`
- `pre-push` runs `bash scripts/test.sh`
- GitHub Actions runs the same check on pushes and pull requests

The shared gate lives in [scripts/test.sh](scripts/test.sh).

For a disposable Ubuntu smoke test of the real installer, use:

```bash
bash scripts/vm-smoke-test.sh
```

That launches a temporary Multipass VM, copies the repo into it, runs the fast checks, then runs a real `system` bootstrap smoke test inside the guest.

Useful variants:

```bash
bash scripts/vm-smoke-test.sh --keep
bash scripts/vm-smoke-test.sh --full
```

## Notes

- Run the repo as a normal user with `sudo` access.
- Dotfiles are backed up before being overwritten.
- Git identity (name + email) is set interactively during `--include-git` and is not hardcoded.
- `mise` activation is added to `~/.bashrc` and `.bash_aliases` so future shells can see managed runtimes.
- `ufw` is enabled during the system step. If you need to open additional ports, do so after bootstrap with `sudo ufw allow <port>`.
- GNOME settings are intentionally optional because they are workstation-specific and require a desktop session.
