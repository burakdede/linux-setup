#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> bash -n"
bash -n \
  .githooks/pre-commit \
  .githooks/pre-push \
  run.sh \
  scripts/install-hooks.sh \
  scripts/smoke-system.sh \
  scripts/test.sh \
  scripts/verify-system-smoke.sh \
  scripts/vm-smoke-test.sh \
  system/system.sh \
  sdk/sdk.sh \
  agents/agents.sh \
  git/git.sh \
  dotfiles/dotfiles.sh \
  utils/utils.sh \
  utils/settings.sh

echo "==> shellcheck"
shellcheck \
  .githooks/pre-commit \
  .githooks/pre-push \
  run.sh \
  scripts/install-hooks.sh \
  scripts/smoke-system.sh \
  scripts/test.sh \
  scripts/verify-system-smoke.sh \
  scripts/vm-smoke-test.sh \
  system/system.sh \
  sdk/sdk.sh \
  agents/agents.sh \
  git/git.sh \
  dotfiles/dotfiles.sh \
  utils/utils.sh \
  utils/settings.sh \
  dotfiles/.bash_aliases

echo "==> unittest"
python3 -m unittest discover -s tests -p 'test_*.py' -v
