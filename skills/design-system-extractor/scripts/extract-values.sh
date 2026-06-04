#!/bin/bash
#
# extract-values.sh — Extract and rank raw design values from stylesheets.
#
# Complements scan-tokens.sh: where that finds WHERE tokens are defined,
# this finds WHAT values are actually used across the codebase, ranked by
# frequency. High-frequency values are de-facto design tokens even when no
# variable exists for them.
#
# Categories: colors (hex / rgb / hsl), font-families, font-sizes,
# spacing (px/rem), border-radius, transitions/animations, shadows, z-index.
#
# Output: JSON with each category mapping value -> occurrence count (top 40).
# Status messages go to stderr.
#
# Usage: bash extract-values.sh [repo_root]

set -euo pipefail

ROOT="${1:-.}"

if [ ! -d "$ROOT" ]; then
  echo "Error: '$ROOT' is not a directory." >&2
  exit 1
fi

echo "Extracting raw design values from '$ROOT'..." >&2

# Style + component files worth scanning.
INCLUDE_RE='\.(css|scss|sass|less|styl|ts|tsx|js|jsx|vue|svelte)$'
EXCLUDE_DIR_RE='(/node_modules/|/\.git/|/dist/|/build/|/\.next/|/\.svelte-kit/|/\.nuxt/|/out/|/coverage/|/\.turbo/|/vendor/)'

# Collect candidate files into a temp list.
TMP_FILES=$(mktemp)
TMP_CONTENT=$(mktemp)
cleanup() { rm -f "$TMP_FILES" "$TMP_CONTENT"; }
trap cleanup EXIT

find "$ROOT" -type f 2>/dev/null \
  | grep -E "$INCLUDE_RE" \
  | grep -vE "$EXCLUDE_DIR_RE" > "$TMP_FILES" || true

if [ ! -s "$TMP_FILES" ]; then
  echo "No stylesheet/component files found." >&2
  echo '{"root":"'"$ROOT"'","colors":{},"font_families":{},"font_sizes":{},"spacing":{},"radius":{},"transitions":{},"shadows":{},"z_index":{}}'
  exit 0
fi

# Concatenate once for repeated grepping.
while IFS= read -r f; do
  cat "$f" 2>/dev/null || true
  printf '\n'
done < "$TMP_FILES" > "$TMP_CONTENT"

# rank <regex> [top]  -> emits JSON object {"val":count,...} ranked desc.
rank() {
  local regex="$1"
  local top="${2:-40}"
  grep -oiE "$regex" "$TMP_CONTENT" 2>/dev/null \
    | tr '[:upper:]' '[:lower:]' \
    | sort \
    | uniq -c \
    | sort -rn \
    | head -n "$top" \
    | awk '
      BEGIN { printf "{"; first=1 }
      {
        count=$1
        $1=""
        sub(/^ /,"")
        val=$0
        gsub(/\\/,"\\\\",val)
        gsub(/"/,"\\\"",val)
        if (first) { first=0 } else { printf "," }
        printf "\"%s\":%d", val, count
      }
      END { printf "}" }
    '
}

echo "  - colors..." >&2
COLORS=$(rank '#[0-9a-fA-F]{3,8}\b|rgba?\([^)]*\)|hsla?\([^)]*\)')

echo "  - font families..." >&2
FONTS=$(rank 'font-family\s*:\s*[^;}]+')

echo "  - font sizes..." >&2
FONT_SIZES=$(rank 'font-size\s*:\s*[0-9.]+(px|rem|em|%)')

echo "  - spacing..." >&2
SPACING=$(rank '(margin|padding|gap)[a-z-]*\s*:\s*[0-9.]+(px|rem|em)')

echo "  - border radius..." >&2
RADIUS=$(rank 'border-radius\s*:\s*[0-9.]+(px|rem|em|%)')

echo "  - transitions/animations..." >&2
TRANSITIONS=$(rank '(transition|animation)[a-z-]*\s*:\s*[^;}]+')

echo "  - shadows..." >&2
SHADOWS=$(rank 'box-shadow\s*:\s*[^;}]+')

echo "  - z-index..." >&2
ZINDEX=$(rank 'z-index\s*:\s*-?[0-9]+')

echo "Done." >&2

printf '{'
printf '"root":"%s",' "$ROOT"
printf '"colors":%s,'        "$COLORS"
printf '"font_families":%s,' "$FONTS"
printf '"font_sizes":%s,'    "$FONT_SIZES"
printf '"spacing":%s,'       "$SPACING"
printf '"radius":%s,'        "$RADIUS"
printf '"transitions":%s,'   "$TRANSITIONS"
printf '"shadows":%s,'       "$SHADOWS"
printf '"z_index":%s'        "$ZINDEX"
printf '}\n'
