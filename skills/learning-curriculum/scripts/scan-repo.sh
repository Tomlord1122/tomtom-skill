#!/bin/bash
# scan-repo.sh — inventory files a learning curriculum must read
# Usage: bash scan-repo.sh [project-root]
# Status → stderr; JSON → stdout
set -euo pipefail

ROOT="${1:-.}"
if [ ! -d "$ROOT" ]; then
  echo "Error: not a directory: $ROOT" >&2
  echo '{"ok":false,"error":"not a directory"}'
  exit 1
fi

ROOT="$(cd "$ROOT" && pwd)"
echo "Scanning $ROOT" >&2

python3 - "$ROOT" <<'PY'
import json, os, sys
root = sys.argv[1]
skip = {".git", "vendor", "node_modules", ".build", "dist"}

def exists(rel):
    return os.path.exists(os.path.join(root, rel))

def walk_match(predicate, limit=25):
    hits = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in skip]
        for name in filenames:
            rel = os.path.relpath(os.path.join(dirpath, name), root)
            if predicate(rel, name):
                hits.append(rel)
                if len(hits) >= limit:
                    return hits
    return hits

payload = {
    "ok": True,
    "root": root,
    "markers": {
        "README": exists("README.md"),
        "AGENTS": exists("AGENTS.md"),
        "Makefile": exists("Makefile"),
        "go.mod": exists("go.mod"),
        "package.json": exists("package.json"),
        "dockerfile": exists("Dockerfile") or exists("docker/Dockerfile"),
        "openapi": exists("docs/openapi/openapi.yml") or exists("docs/openapi/openapi.yaml"),
        "copilot_instructions": exists(".github/copilot-instructions.md"),
    },
    "entrypoints": walk_match(lambda rel, name: name in ("main.go", "main.ts", "main.py") or rel.endswith("/main.go")),
    "tests": walk_match(lambda rel, name: name.endswith("_test.go") or name.endswith(".test.ts") or name.endswith("_test.py") or name.endswith(".hurl")),
    "migrations": walk_match(lambda rel, name: "/migrations/" in rel.replace("\\", "/") and name.endswith(".sql")),
    "ci": walk_match(lambda rel, name: rel.startswith(".github/workflows/")),
}
print(json.dumps(payload, indent=2))
PY
