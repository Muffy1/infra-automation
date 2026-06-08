#!/usr/bin/env bash
# batch-adopt.sh — adopt many repos quickly.
# Skips labels and content (those are nice-to-have, expensive in API calls).
# Usage: cat repos.txt | bash batch-adopt.sh
#        bash batch-adopt.sh muffy86/repo1 muffy86/repo2 ...
set -uo pipefail

if [[ $# -gt 0 ]]; then
  REPOS=("$@")
else
  REPOS=()
  while read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    REPOS+=("$line")
  done
fi

TOTAL=${#REPOS[@]}
OK=0
SKIPPED=0
FAILED=0

adopt_one() {
  local repo="$1"
  local out
  out=$(gh api "repos/$repo" 2>/dev/null) || { echo "  SKIP $repo (api error)"; SKIPPED=$((SKIPPED+1)); return; }
  if ! echo "$out" | jq -e '.full_name' >/dev/null 2>&1; then
    echo "  SKIP $repo (no access)"
    SKIPPED=$((SKIPPED+1))
    return
  fi
  local branch priv
  branch=$(echo "$out" | jq -r '.default_branch')
  priv=$(echo "$out" | jq -r '.private')

  gh api -X PUT "repos/$repo/vulnerability-alerts" >/dev/null 2>&1
  gh api -X PUT "repos/$repo/automated-security-fixes" >/dev/null 2>&1
  gh api -X PUT "repos/$repo/branches/$branch/protection" \
    -H "Accept: application/vnd.github+json" --input - >/dev/null 2>&1 <<JSON
{
  "required_status_checks": {"strict": false, "contexts": []},
  "enforce_admins": false,
  "required_pull_request_reviews": {"dismiss_stale_reviews": true, "required_approving_review_count": 1},
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true,
  "lock_branch": false
}
JSON
  gh api -X POST "repos/$repo/branches/$branch/protection/required_signatures" >/dev/null 2>&1

  OK=$((OK+1))
  printf "  ✓ %-45s %-7s priv=%s\n" "$repo" "$branch" "$priv"
}

echo "=== batch-adopt: $TOTAL repos ==="
START=$(date +%s)
i=0
for repo in "${REPOS[@]}"; do
  i=$((i+1))
  printf "[%d/%d] %s ...\n" "$i" "$TOTAL" "$repo"
  adopt_one "$repo"
done
END=$(date +%s)
echo ""
echo "=== done in $((END-START))s: ok=$OK skipped=$SKIPPED ==="
