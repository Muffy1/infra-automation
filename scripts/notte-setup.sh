#!/usr/bin/env bash
# notte-setup.sh — install and verify Notte browser automation SDK
set -euo pipefail

echo "==> Setting up Notte browser automation"

echo "  Installing notte-sdk (Python)..."
pip install notte-sdk
python3 -c "from notte_sdk import NotteClient; print('  ✓ notte-sdk installed')"

if command -v npm &>/dev/null; then
  echo "  Installing notte-sdk (npm)..."
  npm install --save notte-sdk 2>/dev/null || echo "  ⚠ npm install skipped (no package.json in cwd)"
fi

if [ -z "${NOTTE_API_KEY:-}" ]; then
  echo ""
  echo "  ⚠  NOTTE_API_KEY is not set."
  echo "  Get your free API key at: https://console.notte.cc"
  echo "  Then add to your environment:"
  echo "    export NOTTE_API_KEY=\"notte-...\""
  echo "  Or add to .env:"
  echo "    echo \"NOTTE_API_KEY=notte-...\" >> .env"
else
  echo "  ✓ NOTTE_API_KEY is set"
fi

echo ""
echo "==> Done. Verify with: notte sessions list"
