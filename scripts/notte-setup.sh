#!/usr/bin/env bash
# notte-setup.sh — install and configure Notte browser automation
#
# Verified setup path from https://github.com/nottelabs/notte-skills:
#   1. Install the notte CLI
#   2. Authenticate (interactive browser flow or NOTTE_API_KEY for CI)
#   3. Install Python/Node SDKs
#   4. Verify with: notte sessions list
set -euo pipefail

echo "==> Setting up Notte browser automation"
echo ""

# ── 1. Install notte CLI ──────────────────────────────────────────────────────
echo "── Installing notte CLI"

if command -v brew &>/dev/null; then
  # macOS / Linux with Homebrew
  brew tap nottelabs/notte-cli https://github.com/nottelabs/notte-cli.git 2>/dev/null || true
  brew install notte || brew upgrade notte
elif command -v go &>/dev/null; then
  # Linux / CI — install via Go toolchain
  go install github.com/nottelabs/notte-cli/cmd/notte@latest
  echo "  ✓ notte installed via Go (ensure ~/go/bin is in PATH)"
else
  echo "  ⚠  Neither brew nor go found."
  echo "  Install Homebrew: https://brew.sh"
  echo "  Or install Go:    https://go.dev/dl/"
  echo "  Then re-run this script."
fi

if command -v notte &>/dev/null; then
  echo "  ✓ notte CLI: $(notte --version 2>&1 | head -1)"
fi
echo ""

# ── 2. Authenticate ───────────────────────────────────────────────────────────
echo "── Authenticating"

if [ -n "${NOTTE_API_KEY:-}" ]; then
  echo "  ✓ NOTTE_API_KEY is set (CI/non-interactive mode)"
  echo "  Skipping interactive login — SDK and CLI will use the env var."
elif command -v notte &>/dev/null; then
  echo "  Running: notte auth login"
  echo "  (A browser window will open — complete the login flow)"
  notte auth login
  notte auth status
else
  echo "  ⚠  NOTTE_API_KEY is not set and notte CLI is not installed."
  echo "  Get your free API key at: https://console.notte.cc"
  echo "  Then: export NOTTE_API_KEY=\"notte-...\""
fi
echo ""

# ── 3. Install Python SDK ─────────────────────────────────────────────────────
echo "── Installing notte-sdk (Python)"
pip install --quiet notte-sdk
python3 -c "from notte_sdk import NotteClient; print('  ✓ notte-sdk (Python) installed')"
echo ""

# ── 4. Install Node SDK (optional) ────────────────────────────────────────────
if command -v npm &>/dev/null; then
  echo "── Installing notte-sdk (Node)"
  npm install --save notte-sdk 2>/dev/null \
    && echo "  ✓ notte-sdk (Node) installed" \
    || echo "  ⚠ npm install skipped (no package.json in cwd — run from your project root)"
  echo ""
fi

# ── 5. Add the official notte skill ──────────────────────────────────────────
if command -v npx &>/dev/null; then
  echo "── Installing official notte-browser skill"
  npx --yes skills add nottelabs/notte-skills
  echo ""
fi

# ── 6. Quickstart: observe/click/fill/scrape ─────────────────────────────────
cat <<'QUICKSTART'
── Quickstart (observe/click/fill/scrape pattern)
──────────────────────────────────────────────────
# Always use trap for session cleanup in scripts:
trap 'notte sessions stop --yes 2>/dev/null || true' EXIT

notte sessions start                                          # start browser session
notte page goto "https://news.ycombinator.com"               # navigate
notte page observe                                            # discover element IDs
notte page scrape --instructions "Extract top 10 story titles as JSON"
notte sessions stop                                           # explicit cleanup

# Export live session as reusable Python workflow:
notte sessions workflow-code   # outputs notte_sdk code you can edit and deploy

# One Notte session per job; store session ID in state.
# On auth/navigation failure, retry from a fresh session (not a resumed one).
──────────────────────────────────────────────────
QUICKSTART

echo ""

# ── 7. Verify ─────────────────────────────────────────────────────────────────
echo "── Verification"
if command -v notte &>/dev/null && { [ -n "${NOTTE_API_KEY:-}" ] || notte auth status &>/dev/null; }; then
  notte sessions list --only-active || echo "  (no active sessions)"
else
  echo "  ✓ SDK installed. Run 'notte sessions list' after authenticating to verify."
fi

echo ""
echo "==> Done. See https://docs.notte.cc for full documentation."
