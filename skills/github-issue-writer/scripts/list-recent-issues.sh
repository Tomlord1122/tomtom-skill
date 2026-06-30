#!/usr/bin/env bash
# list-recent-issues.sh — list recent GitHub issues for style reference
# Usage: bash list-recent-issues.sh [owner/repo] [limit]
set -euo pipefail

REPO="${1:-}"
LIMIT="${2:-10}"

if [[ -z "$REPO" ]]; then
  if gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null; then
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
  else
    echo "Usage: $0 <owner/repo> [limit]" >&2
    exit 1
  fi
fi

echo "Repo: $REPO"
echo "Recent issues (limit $LIMIT):"
echo ""
gh issue list --repo "$REPO" --limit "$LIMIT" --json number,title,labels,state \
  --template '{{range .}}#{{.number}} [{{.state}}] {{.title}} ({{range .labels}}{{.name}} {{end}})
{{end}}'