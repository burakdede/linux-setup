#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ "${LINUX_SETUP_SMOKE_FULL:-0}" != "1" ]]; then
    export LINUX_SETUP_SKIP_SNAPS="${LINUX_SETUP_SKIP_SNAPS:-1}"
    export LINUX_SETUP_SKIP_CHROME="${LINUX_SETUP_SKIP_CHROME:-1}"
fi

echo "==> Running system smoke install"
bash run.sh --only system

echo "==> Verifying system smoke install"
bash scripts/verify-system-smoke.sh
