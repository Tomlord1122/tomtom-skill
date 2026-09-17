# Anti-patterns (wrong learning docs)

| Draft you are about to write | Why it fails the exam | Write this instead |
|---|---|---|
| "Architecture overview" + directory tree | Reader cannot start `main` | Skeleton phase: health + config + logger |
| "All SQL then all HTTP" | First test needs the whole universe | One POST through all layers |
| Generic "use interfaces in Go" | No types from this repo | Show `CaseService` in handler, mock in tests |
| Paste `postgres_*_repository.go` | Nobody rebuilds from a 1000-line dump | One INSERT + one `ErrNoRows` convention |
| Trust README endpoints | Stale paths / wrong status codes | OpenAPI `paths:` + generated `ServerInterface` + tests |
| OTel / S3 on day 1 | Cannot tell which layer broke | First slice has no collector and no bucket |
| Hide inverted dependencies | They will copy the package graph | "Don't copy: service importing handler errors" |
| Chat dump of the whole curriculum | Unreadable | Point at `learning/README.md` |
