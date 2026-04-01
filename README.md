# Ubuntu Developer Machine Setup

This repository bootstraps a fresh Ubuntu machine for development work with a bias toward maintainable, repeatable setup and strong support for terminal-first coding agents.

The default path installs:
- core agent-oriented Ubuntu packages from `apt`
- command compatibility symlinks for `fd` and `bat`
- Google Chrome from its official repository
- Docker CLI and Compose plugin from Docker's official repository
- GitHub-release binaries for `yq`, `eza`, `sd`, and `scc`
- `uv` tools such as Ruff and Yamllint
- `mise` as the runtime manager, with Node LTS for Node-based CLIs
- terminal coding agents such as Codex, Claude Code, Gemini CLI, plus `eslint` and `prettier`
- personal dotfiles and web app launchers

Interactive or highly personal steps are opt-in:
- GitHub SSH setup: `./run.sh --include-git`
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

## What Is Considered Essential

This repo now treats the following categories as the base layer for coding agents:
- search and navigation: `rg`, `fd`, `tree`, `fzf`, `eza`
- file inspection and structured parsing: `bat`, `jq`, `yq`
- safer text transforms and repo understanding: `sd`, `scc`
- quality gates: `shellcheck`, `ruff`, `yamllint`, `eslint`, `prettier`
- agent CLIs: `codex`, `claude`, `gemini`
- runtime management: `mise` instead of `nvm`

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
```

Include optional modules:

```bash
./run.sh --include-git --include-settings
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

The shared gate lives in [scripts/test.sh](/home/burak/Projects/linux-setup/scripts/test.sh).

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
- `mise` activation is added to `~/.bashrc` and `.bash_aliases` so future shells can see managed runtimes.
- GNOME settings are intentionally optional because they are workstation-specific and require a desktop session.
