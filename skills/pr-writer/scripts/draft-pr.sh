#!/usr/bin/env bash
# draft-pr.sh — print commit log between base and HEAD for PR drafting
# Usage: bash draft-pr.sh [base-branch]
set -euo pipefail

BASE="${1:-main}"
REPO_URL=$(git remote get-url origin | sed 's/\.git$//' | sed 's|git@github.com:|https://github.com/|')

echo "Base branch: $BASE"
echo "Repo: $REPO_URL"
echo ""
echo "Commits:"
git log --oneline "${BASE}..HEAD"
echo ""
echo "Commit details:"
git log "${BASE}..HEAD" --format="--- %H%n%s%n%n%b"
