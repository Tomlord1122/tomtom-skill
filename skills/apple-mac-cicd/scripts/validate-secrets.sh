#!/bin/bash

set -euo pipefail

TYPE=""

usage() {
  echo "Usage: $0 [--type native|electron|auto]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      TYPE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

if [[ -z "$TYPE" ]]; then
  if [[ -f "Package.swift" ]] || [[ -f "build_dmg.sh" ]]; then
    TYPE="native"
  elif [[ -f "electron-builder.yml" ]] || [[ -f "package.json" && -d "node_modules/electron" ]]; then
    TYPE="electron"
  else
    TYPE="auto"
  fi
fi

if [[ "$TYPE" == "auto" ]]; then
  echo "Could not detect app type. Use --type native or --type electron." >&2
  exit 1
fi

missing=()
present=()

mark() {
  local name="$1"
  if [[ -n "${!name:-}" ]]; then
    present+=("$name")
  else
    missing+=("$name")
  fi
}

if [[ "$TYPE" == "native" ]]; then
  required=(
    APPLE_DEVELOPER_ID_P12_BASE64
    APPLE_DEVELOPER_ID_P12_PASSWORD
    KEYCHAIN_PASSWORD
    DEVELOPER_ID_APPLICATION
    APPLE_ID
    APPLE_APP_SPECIFIC_PASSWORD
    APPLE_TEAM_ID
  )
else
  required=(
    CSC_LINK
    CSC_KEY_PASSWORD
    APPLE_ID
    APPLE_APP_SPECIFIC_PASSWORD
    APPLE_TEAM_ID
  )
fi

for var in "${required[@]}"; do
  mark "$var"
done

printf '{\n  "type": "%s",\n  "present": [' "$TYPE" >&2

first=true
for var in "${present[@]}"; do
  if [[ "$first" == true ]]; then
    first=false
  else
    printf ', ' >&2
  fi
  printf '"%s"' "$var" >&2
done

printf '],\n  "missing": [' >&2

first=true
for var in "${missing[@]}"; do
  if [[ "$first" == true ]]; then
    first=false
  else
    printf ', ' >&2
  fi
  printf '"%s"' "$var" >&2
done

printf '],\n  "ready": %s\n}\n' "$([[ ${#missing[@]} -eq 0 ]] && echo true || echo false)" >&2

cat <<EOF
{
  "type": "$TYPE",
  "present": [$(printf '"%s",' "${present[@]}" | sed 's/,$//')],
  "missing": [$(printf '"%s",' "${missing[@]}" | sed 's/,$//')],
  "ready": $([[ ${#missing[@]} -eq 0 ]] && echo true || echo false)
}
EOF

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Missing secrets: ${missing[*]}" >&2
  exit 1
fi
