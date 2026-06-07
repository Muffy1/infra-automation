#!/usr/bin/env bash
# provision-new-repo.sh
# Bootstrap a new (or existing) muffy86/* repo with full automation.
#
# Usage:
#   ./provision-new-repo.sh REPO_NAME [--public|--private] [--stack node|rust|python|multi]
#   ./provision-new-repo.sh muffy86/foo
#
# Effect:
#   - Creates the repo (if it doesn't exist) with description, topics, README
#   - Adds .github/ folder with workflows calling into infra-automation
#   - Adds CODEOWNERS, dependabot.yml, SECURITY.md, LICENSE
#   - Adds issue + PR templates
#   - Enables Dependabot security updates + vulnerability alerts
#   - Sets branch protection on default branch (linear history, 1 review)
#   - Enables required commit signing
#   - Enables automated security fixes
#   - Adds the standard label set
#
# Requires: gh CLI authenticated as muffy86, jq, curl

set -euo pipefail

REPO="${1:-}"
shift || true
VISIBILITY="--public"
STACK="multi"
DESCRIPTION=""
HOMEPAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --public)  VISIBILITY="--public" ;;
    --private) VISIBILITY="--private" ;;
    --stack)   STACK="$2"; shift ;;
    --desc)    DESCRIPTION="$2"; shift ;;
    --home)    HOMEPAGE="$2"; shift ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
  shift
done

if [[ -z "$REPO" ]]; then
  echo "Usage: $0 REPO [--public|--private] [--stack node|rust|python|multi] [--desc '...'] [--home URL]" >&2
  exit 1
fi

OWNER=$(echo "$REPO" | cut -d/ -f1)
NAME=$(echo "$REPO" | cut -d/ -f2)
[[ -z "$NAME" ]] && { echo "REPO must be in owner/name form (got '$REPO')" >&2; exit 1; }

if ! command -v gh >/dev/null; then
  echo "gh CLI required. Install: https://cli.github.com" >&2; exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "gh CLI not authenticated. Run: gh auth login" >&2; exit 1
fi

if [[ -z "$DESCRIPTION" ]]; then
  DESCRIPTION="Muffy's ${NAME} — auto-provisioned by infra-automation"
fi

echo "=== provisioning $REPO (stack=$STACK, visibility=$VISIBILITY) ==="

# 1. Create if missing
if ! gh repo view "$REPO" >/dev/null 2>&1; then
  echo "  • creating repo"
  gh repo create "$REPO" "$VISIBILITY" --description "$DESCRIPTION" --add-readme \
    ${HOMEPAGE:+--homepage "$HOMEPAGE"}
else
  echo "  • repo already exists, updating"
  gh api -X PATCH "repos/$REPO" -f description="$DESCRIPTION" \
    ${HOMEPAGE:+-f homepage="$HOMEPAGE"} >/dev/null
fi

# 2. Clone into temp
WORKDIR=$(mktemp -d)
trap "rm -rf $WORKDIR" EXIT
gh repo clone "$REPO" "$WORKDIR" -- --depth=1
cd "$WORKDIR"

# 3. Write .github scaffolding
mkdir -p .github/ISSUE_TEMPLATE .github/workflows

cat > .github/CODEOWNERS <<'CO'
*       @muffy86
/.env*                          @muffy86
**/secrets*                     @muffy86
CO

cat > .github/dependabot.yml <<'YAML'
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule: { interval: "weekly", day: "wednesday" }
    open-pull-requests-limit: 5
    labels: ["area:deps", "automated"]
  - package-ecosystem: "pip"
    directory: "/"
    schedule: { interval: "weekly", day: "monday" }
    open-pull-requests-limit: 10
    labels: ["area:deps", "automated"]
    commit-message: { prefix: "deps", prefix-development: "deps-dev" }
  - package-ecosystem: "npm"
    directory: "/"
    schedule: { interval: "weekly", day: "tuesday" }
    open-pull-requests-limit: 10
    labels: ["area:deps", "automated"]
    commit-message: { prefix: "deps", prefix-development: "deps-dev" }
  - package-ecosystem: "cargo"
    directory: "/"
    schedule: { interval: "weekly", day: "thursday" }
    open-pull-requests-limit: 10
    labels: ["area:deps", "automated"]
    commit-message: { prefix: "deps" }
YAML

# 4. CI workflow that delegates to infra-automation
case "$STACK" in
  node)
    cat > .github/workflows/ci.yml <<'YAML'
on: [push, pull_request]
jobs:
  ci:
    uses: muffy86/infra-automation/.github/workflows/ci-node.yml@main
    with: { node-version: "20", package-manager: "pnpm" }
YAML
    ;;
  rust)
    cat > .github/workflows/ci.yml <<'YAML'
on: [push, pull_request]
jobs:
  ci:
    uses: muffy86/infra-automation/.github/workflows/ci-rust.yml@main
    with: { rust-toolchain: "stable" }
YAML
    ;;
  python)
    cat > .github/workflows/ci.yml <<'YAML'
on: [push, pull_request]
jobs:
  ci:
    uses: muffy86/infra-automation/.github/workflows/ci-python.yml@main
    with: { python-version: "3.12", package-manager: "uv" }
YAML
    ;;
  multi|*)
    cat > .github/workflows/ci.yml <<'YAML'
on: [push, pull_request]
jobs:
  node:
    uses: muffy86/infra-automation/.github/workflows/ci-node.yml@main
    with: { node-version: "20", package-manager: "pnpm" }
  python:
    uses: muffy86/infra-automation/.github/workflows/ci-python.yml@main
    with: { python-version: "3.12", package-manager: "uv" }
  rust:
    uses: muffy86/infra-automation/.github/workflows/ci-rust.yml@main
    with: { rust-toolchain: "stable" }
YAML
    ;;
esac

# 5. Security + stale
cat > .github/workflows/security.yml <<'YAML'
on:
  push: { branches: [main, master] }
  pull_request: { branches: [main, master] }
  schedule: [{ cron: "0 6 * * 1" }]
jobs:
  sec:
    uses: muffy86/infra-automation/.github/workflows/security.yml@main
YAML

cat > .github/workflows/stale.yml <<'YAML'
on:
  schedule: [{ cron: "0 3 * * *" }]
  workflow_dispatch:
jobs:
  stale:
    uses: muffy86/infra-automation/.github/workflows/stale.yml@main
YAML

# 6. Templates
cat > .github/ISSUE_TEMPLATE/bug.md <<'MD'
---
name: Bug
about: Report a bug
title: "[Bug]: "
labels: ["bug", "needs-triage"]
---
## What happened
## Reproduction steps
## Expected
## Actual
## Environment
MD

cat > .github/ISSUE_TEMPLATE/feature.md <<'MD'
---
name: Feature
about: Propose a new feature
title: "[Feature]: "
labels: ["enhancement", "needs-triage"]
---
## Problem
## Proposed solution
## Acceptance criteria
MD

cat > .github/PULL_REQUEST_TEMPLATE.md <<'MD'
## Summary
## Why
## Changes
## How to verify
## Risk
## Checklist
- [ ] Self-reviewed
- [ ] Tests
- [ ] Docs
- [ ] No secrets
MD

# 7. SECURITY + LICENSE
cat > SECURITY.md <<'MD'
# Security policy
Email muffy86@users.noreply.github.com with `[security] <topic>` in the subject.
Ack within 72h. Do not file public issues for security bugs.
MD

[ -f LICENSE ] || cat > LICENSE <<'LIC'
MIT License

Copyright (c) 2026 muffy86

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
LIC

# 8. Commit + push
git add -A
git -c user.email="muffy86@users.noreply.github.com" -c user.name="Muffy" \
  commit -m "ci: provision from infra-automation (stack=$STACK)" --allow-empty
git push origin HEAD 2>&1 | tail -3

# 9. Repo-level settings
echo "  • enabling vulnerability alerts + automated security fixes"
gh api -X PUT "repos/$REPO/vulnerability-alerts" 2>&1 >/dev/null
gh api -X PUT "repos/$REPO/automated-security-fixes" 2>&1 >/dev/null

# 10. Branch protection
DEFAULT_BRANCH=$(gh repo view "$REPO" --json defaultBranchRef -q .defaultBranchRef.name)
echo "  • setting branch protection on $DEFAULT_BRANCH"
gh api -X PUT "repos/$REPO/branches/$DEFAULT_BRANCH/protection" --input - <<JSON >/dev/null
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

# 11. Required signing
gh api -X POST "repos/$REPO/branches/$DEFAULT_BRANCH/protection/required_signatures" 2>&1 >/dev/null

# 12. Apply labels
echo "  • applying label set"
for label in \
  "bug|d73a4a" "enhancement|a2eeef" "documentation|0075ca" "question|d876e3" "duplicate|cfd3e7" \
  "area:frontend|1d76db" "area:backend|5319e7" "area:ci|bfe5bf" "area:docs|0e8a16" "area:deps|0366d6" "area:infra|c5defb" \
  "priority:p0|b60205" "priority:p1|d93f0b" "priority:p2|fbca04" "priority:p3|0e8a16" \
  "needs-triage|ededed" "in-progress|0e8a16" "blocked|e99695" "wontfix|ffffff" "stale|c5defb" \
  "size:small|bfdadc" "size:medium|fef2c0" "size:large|f9d0c4" \
  "security|b60205" "breaking-change|b60205" "good-first-issue|7057ff" "help-wanted|008672" "pinned|0e8a16" "epic|5319e7" "automated|c5defb"
do
  NAME=$(echo "$label" | cut -d'|' -f1)
  COLOR=$(echo "$label" | cut -d'|' -f2)
  out=$(gh api -X POST "repos/$REPO/labels" -f name="$NAME" -f color="$COLOR" 2>&1 || true)
  if echo "$out" | grep -q "already_exists"; then : ; fi
done

echo "=== done. $REPO is fully provisioned. ==="
