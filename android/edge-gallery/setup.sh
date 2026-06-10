#!/usr/bin/env bash
# One-shot full setup: install → configure → push starter model → Z Fold tune.
# Prereq: device already connected (run scripts/00-wireless-adb.sh first).
set -euo pipefail
cd "$(dirname "$0")"

adb get-state >/dev/null 2>&1 || { echo "No device connected — running pairing helper..."; ./scripts/00-wireless-adb.sh; }

./scripts/01-install.sh
./scripts/02-configure.sh
./scripts/04-zfold-tune.sh

# Starter model: Qwen 2.5 1.5B is ungated (no HF token needed) and runs well on GPU.
# Pass HF_TOKEN and edit the list below for Gemma models.
./scripts/03-models.sh qwen2.5-1.5b

echo
echo "All done. Open AI Edge Gallery → '+' → import the model from Download."
