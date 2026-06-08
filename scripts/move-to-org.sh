#!/usr/bin/env bash
# move-to-org.sh — transfer selected repos to muffy86-projects org
# (or any target org passed via --org)
#
# Usage:
#   bash scripts/move-to-org.sh [--org muffy86-projects] [--dry-run]
#
# Prerequisites:
#   1. muffy86-projects org must exist (create at https://github.com/organizations/new)
#   2. gh CLI authenticated with a token that has admin:org + repo scopes
#
# The script checks that the org exists before attempting any transfers.
set -euo pipefail

TARGET_ORG="muffy86-projects"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --org) TARGET_ORG="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# ── Repos to transfer ─────────────────────────────────────────────────────────
# Adjust this list to match which repos you want moved.
# Format: "owner/repo"
REPOS_TO_MOVE=(
  "muffy86/agent-workspace"
  "muffy86/infra-automation"
  "muffy86/kortix-skills"
  "muffy86/kortix-mcp"
  "muffy86/hardware-bridge"
  "muffy86/local-dev-orchestrator"
  "muffy86/repo-provisioner"
  "muffy86/github-supercharger"
)

# ── Guard: verify org exists ──────────────────────────────────────────────────
if ! gh api "orgs/$TARGET_ORG" --silent 2>/dev/null; then
  echo "ERROR: org '$TARGET_ORG' not found or not accessible."
  echo ""
  echo "  Create it at: https://github.com/organizations/new"
  echo "  Then re-run this script."
  exit 1
fi
echo "Target org verified: $TARGET_ORG"
echo ""

PASS=0
FAIL=0
SKIP=0

for FULL in "${REPOS_TO_MOVE[@]}"; do
  OWNER="${FULL%%/*}"
  REPO="${FULL##*/}"

  # Check repo exists
  if ! gh api "repos/$OWNER/$REPO" --silent 2>/dev/null; then
    echo "SKIP  $FULL (not found)"
    (( SKIP++ )) || true
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY   would transfer $FULL → $TARGET_ORG"
    continue
  fi

  echo -n "Transferring $FULL → $TARGET_ORG ... "
  if gh api -X POST "repos/$OWNER/$REPO/transfer" \
       -f new_owner="$TARGET_ORG" \
       --silent; then
    echo "OK"
    (( PASS++ )) || true
  else
    echo "FAIL"
    (( FAIL++ )) || true
  fi
done

echo ""
echo "── move-to-org summary ─────────────────────────────────────────"
if [[ $DRY_RUN -eq 1 ]]; then
  echo "  DRY RUN — no changes made"
  echo "  Would transfer: ${#REPOS_TO_MOVE[@]} repos → $TARGET_ORG"
else
  echo "  Transferred: $PASS"
  echo "  Skipped    : $SKIP (not found)"
  echo "  Failed     : $FAIL"
fi
echo ""
echo "NOTE: After transfer, update any local remotes:"
echo "  git remote set-url origin git@github.com:$TARGET_ORG/<repo>.git"
echo "  (clone URLs redirect automatically for 1 year but it's cleaner to update)"
