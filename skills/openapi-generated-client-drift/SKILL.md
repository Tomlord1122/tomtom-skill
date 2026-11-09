---
name: openapi-generated-client-drift
description: >-
  Fix CI when OpenAPI clients or frontend formatting fail after an API field change. Use when "Check OpenAPI clients are up to date" or "Check formatting" fails, or when generated Go or TypeScript types disagree with openapi.yaml.
metadata:
  cometline:
    origin: self-improvement
---

# OpenAPI generated client drift

Hand-edited generated types and unformatted Svelte both fail CI after the product code already typechecks. Regenerate from the spec, then format the files the feature touched. Commit both. Do not edit generated files by hand to match the spec.

## Steps

1. Read the failed job steps, not the run summary. Two different jobs often fail together:
   - Generated code fails on `Check OpenAPI clients are up to date`.
   - Frontend fails on `Check formatting` after typecheck and lint already passed.
2. Treat `cometmind/openapi.yaml` as the contract. Generated outputs are:
   - `cometline/src/lib/generated/cometmind-api/` (`@hey-api/openapi-ts`)
   - `cometmind/internal/apigen/types.gen.go` (`oapi-codegen`)
3. From the repository root, regenerate both:

```bash
make generate
```

That runs `pnpm run generate:api` in `cometline` and `go generate ./internal/apigen` in `cometmind`. An OpenAPI 3.1 warning from oapi-codegen is expected here; it is not the failure.
4. Confirm the generator actually moved something:

```bash
git diff --stat -- cometline/src/lib/generated/cometmind-api cometmind/internal/apigen/types.gen.go
```

Field order in the generated Go struct follows the generator, not the order you pasted in. A hand-placed field that typechecks locally still fails `git diff --exit-code` in `make check-generated`.
5. Format only the frontend files this change touched. Prettier with the Svelte plugin wraps long calls differently than a manual line break, including `{@const}` inside `{#each}`:

```bash
cd cometline && pnpm exec prettier --write <touched .svelte .ts paths>
```

`format:check` is `prettier --check .`. Typecheck passing does not imply formatting passed.
6. Stage the regenerated types and the formatted files. Commit them with the same sign-off as the rest of the branch (`git commit -s`) and push so CI reruns.

## Pitfalls

- Do not patch `types.gen.go` or the TypeScript client by hand to "look like" the YAML. The CI check regenerates and diffs. A field in the right struct but the wrong position still fails.
- Do not assume the frontend job failed tests. If the failed step is `Check formatting` and Test was skipped, the fix is prettier, not a test change.
- Do not run prettier on the whole tree when only a few files are dirty. Format the files the feature added or edited so unrelated drift does not ride along.
- A 3.1 warning from `go generate ./internal/apigen` is not evidence the generator failed. Look at `git diff` on `types.gen.go`.