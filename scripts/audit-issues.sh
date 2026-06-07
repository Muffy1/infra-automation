#!/usr/bin/env bash
# audit-issues.sh
# Snapshot open issues + PRs for a repo and produce a triage report.
#
# Usage: ./audit-issues.sh owner/repo [--days N]
set -euo pipefail
REPO="${1:?usage: $0 owner/repo [--days N]}"
DAYS=30
[[ "${2:-}" == "--days" ]] && DAYS="${3:-30}"

echo "=== $REPO issue/PR audit (last ${DAYS}d) ==="
gh issue list --repo "$REPO" --state open --limit 200 --json number,title,labels,createdAt,updatedAt \
  | jq -r '.[] | [.number, .title, (.labels | map(.name) | join(",")), .createdAt, .updatedAt] | @tsv' \
  | awk -F'\t' -v cutoff="$(date -u -d "$DAYS days ago" +%s)" '
    {
      cmd="date -u -d "$5" +%s"; cmd | getline updated; close(cmd);
      age=$((cutoff - updated));
      printf "  #%s [%dd]  %s  %s\n", $1, age/86400, $4, $2
    }' 2>/dev/null || true

echo ""
echo "=== PRs ==="
gh pr list --repo "$REPO" --state open --limit 100 --json number,title,isDraft,createdAt,updatedAt \
  | jq -r '.[] | [.number, .title, .isDraft, .createdAt, .updatedAt] | @tsv' \
  | awk -F'\t' -v cutoff="$(date -u -d "$DAYS days ago" +%s)" '
    {
      cmd="date -u -d "$5" +%s"; cmd | getline updated; close(cmd);
      age=$((cutoff - updated));
      draft=($3=="true" ? "[DRAFT] " : "");
      printf "  #%s [%dd]  %s%s\n", $1, age/86400, draft, $2
    }' 2>/dev/null || true
