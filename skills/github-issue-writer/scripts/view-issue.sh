#!/usr/bin/env bash
# view-issue.sh — print full issue body for style reference
# Usage: bash view-issue.sh <issue-number> [owner/repo]
set -euo pipefail

NUMBER="${1:-}"
REPO="${2:-}"

if [[ -z "$NUMBER" ]]; then
  echo "Usage: $0 <issue-number> [owner/repo]" >&2
  exit 1
fi

if [[ -z "$REPO" ]]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
fi

gh issue view "$NUMBER" --repo "$REPO"