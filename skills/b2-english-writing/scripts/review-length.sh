#!/bin/bash
set -e

# A rough review aid, not a CEFR or readability test.
file=${1:-}
if [ -z "$file" ] || [ ! -f "$file" ] || [ ! -r "$file" ]; then
  echo "Usage: bash review-length.sh <readable-markdown-file>" >&2
  exit 1
fi

echo "Checking prose line lengths; review the context before changing anything." >&2
awk '
  BEGIN { in_fence = 0; prose_lines = 0; long_lines = 0 }
  /^```/ || /^~~~/ { in_fence = !in_fence; next }
  in_fence || /^[[:space:]]*$/ || /^#/ || /^\|/ || /^---[[:space:]]*$/ { next }
  {
    prose_lines++
    if (NF > 35) long_lines++
  }
  END {
    printf "{\"prose_lines\":%d,\"lines_over_35_words\":%d}\n", prose_lines, long_lines
  }
' "$file"
