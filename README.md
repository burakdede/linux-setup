# Ubuntu Developer Machine Setup

This repository bootstraps an Ubuntu workstation for development with a bias toward repeatability, terminal-first workflows, and coding-agent support.

It started as a personal machine setup, but the default path is intentionally generic enough to be useful on a fresh Ubuntu developer box without requiring repo-specific edits.

## What You Get

Running the default bootstrap installs a practical base layer for coding work:
- core Ubuntu packages from `apt`
- command compatibility symlinks for `fd` and `bat`
- Google Chrome from the official Google repository
- Docker CLI and Compose plugin from the official Docker repository
- selected standalone tools from GitHub releases such as `yq`, `eza`, `sd`, and `scc`
- `uv` plus Python-based developer tools
- `mise` with pinned Node, Go, and Python toolchains
- `rustup` with a pinned Rust toolchain
- terminal coding tools such as Codex, Claude Code, Gemini CLI, `eslint`, and `prettier`
- zsh shell profiles with two fast prompt/plugin options: `antidote+p10k` (default) and `zsh4humans`
- dotfiles, shell, editor, terminal, tmux, SDK, and agent configuration steps

Default run includes all steps (including GitHub SSH setup and GNOME settings).
Use skip flags when you want a non-interactive path:
- Skip GitHub SSH setup: `./run.sh --skip-git`
- Skip GNOME desktop settings: `./run.sh --skip-settings`

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
4. Verify the result:
   ```bash
   ./run.sh --verify
   ```

Run the repository as a normal user with `sudo` access.

## Common Commands

Run the full setup:

```bash
./run.sh
```

For unattended runs, preseed Git identity so configure step never waits for input:

```bash
LINUX_SETUP_GIT_NAME="Your Name" LINUX_SETUP_GIT_EMAIL="you@example.com" ./run.sh
```

Run only specific steps:

```bash
./run.sh --only system
./run.sh --only dotfiles
./run.sh --only agents
```

Run with explicit skips:

```bash
./run.sh --skip-git --skip-settings
```

Show available steps:

```bash
./run.sh --help
```

## Documentation

The README stays focused on the initial path. More detailed guidance lives under `docs/`:

- [docs/getting-started.md](/Users/burakdede/Projects/linux-setup/docs/getting-started.md): install flow, step ordering, and verification
- [docs/customization.md](/Users/burakdede/Projects/linux-setup/docs/customization.md): skip flags, optional modules, manifests, version pins, and personal tailoring
- [docs/reference.md](/Users/burakdede/Projects/linux-setup/docs/reference.md): installed categories, MCP setup, local gates, CI smoke tests, and operational notes
- [docs/control-map.md](/Users/burakdede/Projects/linux-setup/docs/control-map.md): who owns each terminal-stack layer and where to edit it in-repo and post-install

## Design Principles

- Base bootstrap should be non-interactive and rerunnable.
- Personal preferences should be easy to opt into or replace.
- Version-sensitive toolchains should be pinned instead of floating to `latest`.
- Package choices should live in manifests where possible.
- The machine should be usable for both human terminal workflows and coding agents.

## Notes

- Dotfiles are backed up before being replaced.
- `ufw` is enabled during the system step unless you skip it.
- Git identity is written to `~/.gitconfig.local`, not hardcoded in the repo.
- Agent configuration is generated locally and may still require filling in your own API tokens.
