#!/usr/bin/env bash
# archive-duplicates.sh — archive the known duplicate/scratch/empty repos
# Usage: bash scripts/archive-duplicates.sh [--dry-run]
#
# Targets (19 repos):
#   8 confirmed duplicates
#   5 stems (partial/abandoned)
#   6 empty repos
set -euo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# ── Edit this list if you want to add/remove repos before running ─────────────
DUPLICATES=(
  # 8 confirmed duplicates — superseded by infra-automation or agent-workspace
  "muffy86/kortix-infra"
  "muffy86/kortix-automation"
  "muffy86/agent-workspace-old"
  "muffy86/workspace-backup"
  "muffy86/kortix-scripts"
  "muffy86/infra-scripts-v1"
  "muffy86/muffy-automation"
  "muffy86/runner-setup"
)

STEMS=(
  # 5 stems — partial/abandoned, never reached working state
  "muffy86/kortix-mcp-draft"
  "muffy86/agent-bridge-wip"
  "muffy86/opencode-fork"
  "muffy86/hardware-probe-test"
  "muffy86/kortix-sdk-scratch"
)

EMPTY=(
  # 6 empty repos — no commits, no content
  "muffy86/test-repo-1"
  "muffy86/test-repo-2"
  "muffy86/sandbox"
  "muffy86/temp"
  "muffy86/playground"
  "muffy86/scratch"
)

ALL=("${DUPLICATES[@]}" "${STEMS[@]}" "${EMPTY[@]}")

PASS=0
FAIL=0
SKIP=0

for FULL in "${ALL[@]}"; do
  OWNER="${FULL%%/*}"
  REPO="${FULL##*/}"

  # Check repo actually exists before trying to archive
  if ! gh api "repos/$OWNER/$REPO" --silent 2>/dev/null; then
    echo "SKIP  $FULL (not found or no access)"
    (( SKIP++ )) || true
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY   would archive $FULL"
    continue
  fi

  if gh api -X PATCH "repos/$OWNER/$REPO" \
       -f archived=true \
       --silent; then
    echo "OK    archived $FULL"
    (( PASS++ )) || true
  else
    echo "FAIL  $FULL"
    (( FAIL++ )) || true
  fi
done

echo ""
echo "── archive-duplicates summary ─────────────────────────────────"
if [[ $DRY_RUN -eq 1 ]]; then
  echo "  DRY RUN — no changes made"
  echo "  Would archive: ${#ALL[@]} repos"
else
  echo "  Archived : $PASS"
  echo "  Skipped  : $SKIP (not found)"
  echo "  Failed   : $FAIL"
fi
echo ""
echo "NOTE: To permanently delete a repo use:"
echo "  gh repo delete <owner>/<repo> --yes"
echo "Archives can be unarchived at any time from GitHub Settings."
