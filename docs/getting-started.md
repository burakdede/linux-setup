# Getting Started

## Intended Flow

The default order is:

1. `system`
2. `dotfiles`
3. `configure`
4. `shell`
5. `editor`
6. `multiplexer`
7. `terminal`
8. `sdk`
9. `agents`

That order is already encoded in `./run.sh`, so a plain `./run.sh` is the normal entrypoint on a fresh machine.

## Base Install

Install Git, clone the repository, and run:

```bash
./run.sh
```

This path is meant to work for a generic Ubuntu developer workstation with `sudo` access.

## Optional Steps

Two steps are intentionally excluded from the base path because they are either interactive or desktop-specific:

- `./run.sh --include-git`
- `./run.sh --include-settings`

You can combine them with the base run:

```bash
./run.sh --include-git --include-settings
```

## Running Individual Steps

Use `--only` when you want to rerun or isolate a module:

```bash
./run.sh --only system
./run.sh --only dotfiles
./run.sh --only configure
./run.sh --only agents
```

`run.sh` will warn when you select a step without its usual dependency.

## Verification

To check the installed toolchain without making changes:

```bash
./run.sh --verify
```

For repository gates:

```bash
bash scripts/test.sh
```

## After Bootstrap

Typical follow-up actions:

- open a new shell so `mise` and shell changes are active everywhere
- pick your zsh profile (`antidote-p10k` by default, or `zsh4humans`)
- review generated MCP configs and add your own API tokens if needed
- rerun any optional steps you intentionally skipped the first time
- adjust manifests or dotfiles only after the base install is stable
