#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> bash -n"
bash -n run.sh system/system.sh sdk/sdk.sh git/git.sh dotfiles/dotfiles.sh utils/utils.sh utils/settings.sh web2app/web2app.sh

echo "==> shellcheck"
shellcheck run.sh system/system.sh sdk/sdk.sh git/git.sh dotfiles/dotfiles.sh utils/utils.sh utils/settings.sh web2app/web2app.sh dotfiles/.bash_aliases

echo "==> unittest"
python3 -m unittest discover -s tests -p 'test_*.py' -v
