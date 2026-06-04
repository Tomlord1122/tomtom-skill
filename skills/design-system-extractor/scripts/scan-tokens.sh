#!/bin/bash
#
# scan-tokens.sh — Discover design-token sources in a frontend repo.
#
# Detects and locates the files that define a project's design foundation:
#   - Tailwind config (theme tokens)
#   - CSS custom properties (:root / [data-theme] variables)
#   - SCSS/LESS variables
#   - styled-components / emotion / vanilla-extract theme objects
#   - Design-token JSON (Style Dictionary, W3C, Figma Tokens)
#   - Global stylesheets and font definitions
#
# Output: JSON summary to stdout (machine-readable for the agent to act on).
# Status/progress messages go to stderr.
#
# Usage: bash scan-tokens.sh [repo_root]
#   repo_root  Directory to scan. Defaults to current directory.

set -euo pipefail

ROOT="${1:-.}"

if [ ! -d "$ROOT" ]; then
  echo "Error: '$ROOT' is not a directory." >&2
  exit 1
fi

echo "Scanning '$ROOT' for design-token sources..." >&2

# Directories that never contain authored design tokens.
PRUNE=( -name node_modules -o -name .git -o -name dist -o -name build \
        -o -name .next -o -name .svelte-kit -o -name .nuxt -o -name out \
        -o -name coverage -o -name .turbo -o -name vendor )

# find wrapper that prunes noise directories.
ffind() {
  find "$ROOT" \( "${PRUNE[@]}" \) -prune -o "$@" -print 2>/dev/null || true
}

# Emit a JSON array of file paths (relative-ish) from newline input.
json_array() {
  local first=1
  printf '['
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    if [ $first -eq 1 ]; then first=0; else printf ','; fi
    # Escape backslashes and double quotes for JSON.
    line="${line//\\/\\\\}"
    line="${line//\"/\\\"}"
    printf '"%s"' "$line"
  done
  printf ']'
}

# --- Detection passes ------------------------------------------------------

echo "  - Tailwind config..." >&2
TAILWIND=$(ffind -type f \( -name 'tailwind.config.js' -o -name 'tailwind.config.cjs' \
  -o -name 'tailwind.config.mjs' -o -name 'tailwind.config.ts' \))

echo "  - CSS custom properties..." >&2
# Files containing `--var:` declarations or :root blocks.
CSS_VARS=$(ffind -type f \( -name '*.css' -o -name '*.scss' -o -name '*.less' \) \
  | while IFS= read -r f; do
      if grep -lE '(:root|--[a-zA-Z0-9_-]+\s*:)' "$f" >/dev/null 2>&1; then
        echo "$f"
      fi
    done)

echo "  - SCSS/LESS variables..." >&2
PREPROCESSOR_VARS=$(ffind -type f \( -name '*.scss' -o -name '*.sass' -o -name '*.less' \) \
  | while IFS= read -r f; do
      if grep -lE '(\$[a-zA-Z0-9_-]+\s*:|@[a-zA-Z0-9_-]+\s*:)' "$f" >/dev/null 2>&1; then
        echo "$f"
      fi
    done)

echo "  - CSS-in-JS theme objects..." >&2
# styled-components / emotion / vanilla-extract / stitches theme definitions.
CSS_IN_JS=$(ffind -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' \) \
  | while IFS= read -r f; do
      if grep -lE '(createTheme|createGlobalTheme|ThemeProvider|defineConfig|createStitches|styled\.|css`|theme\s*=\s*\{)' "$f" >/dev/null 2>&1; then
        echo "$f"
      fi
    done)

echo "  - Design-token JSON..." >&2
# Heuristic: JSON files whose name or content suggests design tokens.
TOKEN_JSON=$(ffind -type f -name '*.json' \
  | while IFS= read -r f; do
      base=$(basename "$f")
      # Name heuristic.
      if printf '%s' "$base" | grep -qiE 'token|design-system|theme'; then
        echo "$f"
        continue
      fi
      # Content heuristic: W3C/Style-Dictionary token markers.
      if grep -lE '"\$(value|type)"|"value"\s*:.*"(color|dimension|fontFamily)"' "$f" >/dev/null 2>&1; then
        echo "$f"
      fi
    done)

echo "  - Global stylesheets & fonts..." >&2
GLOBAL_CSS=$(ffind -type f \( -name 'global*.css' -o -name 'globals.css' \
  -o -name 'app.css' -o -name 'index.css' -o -name 'main.css' -o -name 'styles.css' \
  -o -name 'reset.css' -o -name 'base.css' -o -name 'theme.css' -o -name 'tokens.css' \))

FONT_DEFS=$(ffind -type f \( -name '*.css' -o -name '*.scss' \) \
  | while IFS= read -r f; do
      if grep -lE '@font-face|font-family' "$f" >/dev/null 2>&1; then
        echo "$f"
      fi
    done)

echo "  - Build/config hints..." >&2
CONFIG_HINTS=$(ffind -type f \( -name 'theme.config.*' -o -name 'design-tokens.*' \
  -o -name 'sd.config.*' -o -name 'style-dictionary.config.*' \
  -o -name 'panda.config.*' -o -name 'uno.config.*' \))

# --- Emit JSON -------------------------------------------------------------

echo "Done. Emitting JSON summary." >&2

{
  printf '{'
  printf '"root":"%s",' "$ROOT"
  printf '"tailwind_config":%s,'      "$(printf '%s\n' "$TAILWIND"          | json_array)"
  printf '"css_variables":%s,'        "$(printf '%s\n' "$CSS_VARS"          | json_array)"
  printf '"preprocessor_variables":%s,' "$(printf '%s\n' "$PREPROCESSOR_VARS" | json_array)"
  printf '"css_in_js":%s,'            "$(printf '%s\n' "$CSS_IN_JS"         | json_array)"
  printf '"token_json":%s,'           "$(printf '%s\n' "$TOKEN_JSON"        | json_array)"
  printf '"global_stylesheets":%s,'   "$(printf '%s\n' "$GLOBAL_CSS"        | json_array)"
  printf '"font_definitions":%s,'     "$(printf '%s\n' "$FONT_DEFS"         | json_array)"
  printf '"config_hints":%s'          "$(printf '%s\n' "$CONFIG_HINTS"      | json_array)"
  printf '}\n'
}
