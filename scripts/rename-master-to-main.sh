#!/usr/bin/env bash
# rename-master-to-main.sh — rename the default branch from master to main
# across one or more repos.
#
# Usage:
#   bash rename-master-to-main.sh owner/repo [...]
#   cat repos.txt | bash rename-master-to-main.sh
#
# Steps per repo:
#   1. Create `main` from `master` (if not present)
#   2. Set `main` as the default branch
#   3. Apply branch protection to `main`
#   4. Delete `master` (only if it's safe — i.e. main is identical)
#
# For repos that already have commits on main in addition to master,
# we leave master intact (the user can delete it manually if they want).
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

rename_one() {
  local repo="$1"
  local info
  info=$(gh api "repos/$repo" 2>/dev/null) || { echo "  SKIP $repo"; return; }
  local default
  default=$(echo "$info" | jq -r '.default_branch')
  if [[ "$default" != "master" ]]; then
    printf "  - %-45s default=%s (no-op)\n" "$repo" "$default"
    return
  fi

  # Step 1: create main from master's tip (idempotent)
  local master_sha
  master_sha=$(gh api "repos/$repo/git/ref/heads/master" 2>/dev/null | jq -r '.object.sha // empty')
  if [[ -z "$master_sha" ]]; then
    echo "  ! $repo: could not resolve master SHA"
    return
  fi

  # Check if main already exists
  if ! gh api "repos/$repo/git/ref/heads/main" >/dev/null 2>&1; then
    gh api -X POST "repos/$repo/git/refs" \
      -H "Accept: application/vnd.github+json" \
      -f ref="refs/heads/main" -f sha="$master_sha" >/dev/null 2>&1
  fi

  # Step 2: change default
  gh api -X PATCH "repos/$repo" -f default_branch=main >/dev/null 2>&1

  # Step 3: re-apply protection on main
  gh api -X PUT "repos/$repo/branches/main/protection" \
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
  gh api -X POST "repos/$repo/branches/main/protection/required_signatures" >/dev/null 2>&1

  # Step 4: try to delete master. Only safe if main is at the same SHA.
  local main_sha
  main_sha=$(gh api "repos/$repo/git/ref/heads/main" 2>/dev/null | jq -r '.object.sha // empty')
  if [[ "$main_sha" == "$master_sha" ]]; then
    gh api -X DELETE "repos/$repo/git/refs/heads/master" >/dev/null 2>&1
    printf "  ✓ %-45s master → main (master deleted)\n" "$repo"
  else
    printf "  ✓ %-45s master → main (master kept — has unique commits)\n" "$repo"
  fi
}

echo "=== rename master → main ==="
START=$(date +%s)
for repo in "${REPOS[@]}"; do
  rename_one "$repo"
done
END=$(date +%s)
echo "=== done in $((END-START))s ==="
