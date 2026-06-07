#!/usr/bin/env bash
# sync-topics.sh
# Apply a standard topic set to a repo (or batch of repos from a file).
#
# Usage: ./sync-topics.sh owner/repo [topic1 topic2 ...]
#        ./sync-topics.sh --from-file repos.txt
set -euo pipefail

if [[ "${1:-}" == "--from-file" ]]; then
  FILE="${2:?need file}"
  while read -r REPO; do
    [[ -z "$REPO" || "$REPO" == \#* ]] && continue
    bash "$0" "$REPO"
  done < "$FILE"
  exit 0
fi

REPO="${1:?usage: $0 owner/repo [--from-file FILE]}"
shift

# Standard topics
TOPICS=("$@")
[[ ${#TOPICS[@]} -eq 0 ]] && TOPICS=(
  "muffy86" "automation" "infra-automation" "kortix" "mcp"
)

NAMES_JSON=$(printf '"%s",' "${TOPICS[@]}")
NAMES_JSON="[${NAMES_JSON%,}]"

gh api -X PUT "repos/$REPO/topics" -H "Accept: application/vnd.github+json" --input - <<JSON
{"names": ${NAMES_JSON}}
JSON

echo "$REPO: topics synced (${#TOPICS[@]})"
