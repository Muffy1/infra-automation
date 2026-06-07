#!/usr/bin/env bash
# protect-main.sh
# Re-apply the standard branch protection rules on a repo's default branch.
#
# Usage: ./protect-main.sh owner/repo
set -euo pipefail
REPO="${1:?usage: $0 owner/repo}"

DEFAULT_BRANCH=$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)
echo "Protecting $REPO on $DEFAULT_BRANCH ..."

gh api -X PUT "repos/$REPO/branches/$DEFAULT_BRANCH/protection" --input - <<JSON
{
  "required_status_checks": {"strict": false, "contexts": []},
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "required_approving_review_count": 1
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true,
  "lock_branch": false
}
JSON

gh api -X POST "repos/$REPO/branches/$DEFAULT_BRANCH/protection/required_signatures" 2>/dev/null || true
echo "Done."
