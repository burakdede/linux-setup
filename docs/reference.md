# Reference

## Base Tooling Categories

This repository treats the following categories as the essential base layer for coding work:

- search and navigation: `rg`, `fd`, `tree`, `fzf`, `eza`
- file inspection and structured parsing: `bat`, `jq`, `yq`
- text transforms and repo understanding: `sd`, `scc`
- quality gates: `shellcheck`, `pre-commit`, `ruff`, `yamllint`, `eslint`, `prettier`
- coding agents: `codex`, `claude`, `gemini`
- runtime management: pinned `mise`, Node, Go, Python, and Rust toolchains

## MCP Configuration

The `agents` step writes MCP configuration for local agent clients.

Generated files:

- `~/.claude.json`
- `~/.openai/mcp.json`

Token-gated integrations such as Linear, Notion, and Miro are written into config but may still require you to fill in your own credentials after bootstrap.

## Local Gates

Install repository-managed hooks once:

```bash
bash scripts/install-hooks.sh
```

After that:

- `pre-commit` runs `bash scripts/test.sh`
- `pre-push` runs `bash scripts/test.sh`
- GitHub Actions runs the same shared check on pushes and pull requests

## CI And Smoke Tests

Shared local gate:

```bash
bash scripts/test.sh
```

Disposable Ubuntu smoke test:

```bash
bash scripts/vm-smoke-test.sh
```

Useful variants:

```bash
bash scripts/vm-smoke-test.sh --keep
bash scripts/vm-smoke-test.sh --full
```

The CI workflow also runs a real Ubuntu system smoke pass to catch upstream packaging and installer drift.

## Operational Notes

- Run the bootstrap as a normal user with `sudo` access.
- Dotfiles are backed up before being overwritten.
- Git identity is written to `~/.gitconfig.local`.
- `mise` activation is added to shell startup files so future shells can see managed runtimes.
- `ufw` is enabled during the system step unless explicitly skipped.
- GNOME settings are optional because they require a desktop session and are usually machine-specific.
