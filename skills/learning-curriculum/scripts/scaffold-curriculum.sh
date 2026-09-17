#!/bin/bash
# scaffold-curriculum.sh — create learning/ stubs for a rebuild curriculum
# Usage: bash scaffold-curriculum.sh [--out learning] [--topics mindset,layers,rebuild]
# Status → stderr; JSON → stdout
set -euo pipefail

OUT="learning"
TOPICS="mindset,layers,rebuild"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      OUT="$2"; shift 2 ;;
    --topics)
      TOPICS="$2"; shift 2 ;;
    *)
      echo "Unknown option: $1" >&2
      echo '{"ok":false,"error":"unknown option"}'
      exit 1 ;;
  esac
done

echo "Scaffolding curriculum into $OUT" >&2
mkdir -p "$OUT"

IFS=',' read -r -a TOPIC_ARR <<< "$TOPICS"
created=()
index=0

slug_to_title() {
  echo "$1" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1'
}

readme_rows=""
for topic in "${TOPIC_ARR[@]}"; do
  topic="$(echo "$topic" | xargs)"
  [ -z "$topic" ] && continue
  num=$(printf "%02d" "$index")
  if [ "$topic" = "rebuild" ]; then
    file="${num}-rebuild.md"
    title="Rebuild this service from scratch"
  else
    file="${num}-${topic}.md"
    title="$(slug_to_title "$topic")"
  fi
  path="${OUT}/${file}"
  if [ ! -f "$path" ]; then
    if [ "$topic" = "rebuild" ]; then
      cat > "$path" <<EOF
# ${index}. ${title}

The repo is the answer key. One vertical slice at a time.

Rule:

    contract → generate → add 1 method to the caller interface
      → repo fake → service + mock repo → handler + mock service
      → pass request ctx → tests green

## Domain a clone must hit

- (fill from tests and OpenAPI paths)

## Phase A — skeleton

**Learn first:** [00-mindset.md](./00-mindset.md)

Checklist:

- [ ] process starts with \`-config\`
- [ ] \`/health\` works
EOF
    elif [ "$topic" = "mindset" ]; then
      cat > "$path" <<EOF
# ${index}. ${title}

A backend service is a process other programs call. It must stay correct when callers retry, disconnect, or send the same payload twice.

## Habits

1. Start from who suffers.
2. The HTTP/API contract is the product.
3. Slice vertically, not by layer.
4. The caller owns the interface.
5. Push I/O to the edge.
6. \`context.Context\` is the request lifetime.
7. Errors are values; HTTP is a translation.
8. Wire the world only in \`main\`.
9. Test the cheapest fake that can prove the rule.

## Exercise

Say, without notes, why this service is more than one package and why write methods take ctx first.
EOF
    else
      cat > "$path" <<EOF
# ${index}. ${title}

Pain: (one sentence, no library name).

## How this repo does it

(Cite a real file. Short snippet.)

## What not to do

-

## Exercise

-
EOF
    fi
    echo "Wrote $path" >&2
  else
    echo "Skip existing $path" >&2
  fi
  created+=("$file")
  readme_rows="${readme_rows}| ${index} | [${file}](./${file}) | ${title} |
"
  index=$((index + 1))
done

if [ ! -f "${OUT}/README.md" ]; then
  cat > "${OUT}/README.md" <<EOF
# Learning path

For a backend newbie who will **rebuild this service from scratch**.

This repo is the **answer key**. Try the rebuild step before peeking.

## Order

| # | File | What you learn |
|---|---|---|
${readme_rows}
Chapters before rebuild are **tools**. The rebuild chapter is when you **use them**.
EOF
  echo "Wrote ${OUT}/README.md" >&2
  created+=("README.md")
fi

python3 - "$OUT" "${created[@]}" <<'PY'
import json, os, sys
out = sys.argv[1]
files = sys.argv[2:]
print(json.dumps({"ok": True, "out": os.path.abspath(out), "files": files}))
PY
