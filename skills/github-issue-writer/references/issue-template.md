# GitHub issue body template (enhancement)

Copy this skeleton when drafting. Replace placeholders; delete sections that do not apply.

```markdown
## Summary

<2-4 sentences: what we should build and why it matters.>

## Problem

- <pain point 1>
- <pain point 2>
- <concrete failure mode or user expectation gap>

## Current behavior

| Layer | Today |
|-------|-------|
| <Settings / API / Runtime / UI / DB> | <what happens now — link key files> |
| ... | ... |

<Optional mermaid diagram when multi-step flow helps.>

## Proposed behavior

### 1. <First major piece>

<Design detail, config shape, API changes.>

### 2. <Second major piece>

...

## Implementation sketch

1. **`<path/>`** — <what to change>
2. **`<path/>`** — <what to change>
3. **Tests** — <what to add>
4. **OpenAPI / codegen** — if contract changes: `make generate`

## Acceptance criteria

- [ ] <testable outcome 1>
- [ ] <testable outcome 2>
- [ ] <tests or manual verification>

## Out of scope (for this issue)

- <explicit non-goals>
- <follow-up issues to file separately>

## Related issues

- #<N> — <one-line relation>

## Related code

- [`path/to/file`](path/to/file)
- [`path/to/other`](path/to/other)
```

## Bug variant

Use title `fix(scope): ...` and replace **Proposed behavior** with **Expected behavior** / **Actual behavior** / **Reproduction steps**.

## Research checklist (before filing)

- [ ] Grepped / read modules for the feature area
- [ ] Documented current behavior with real paths
- [ ] Checked open issues for duplicates (`gh issue list`)
- [ ] Acceptance criteria are verifiable
- [ ] Out of scope lists at least 2 items for non-trivial features