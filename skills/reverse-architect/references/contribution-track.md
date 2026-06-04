# Contribution Track

Use this after Steps 1–6 of the Reverse Architect thinking process are complete. The goal is the **smallest safe change** that achieves the user's intent without violating an invariant.

A contributor and a rebuilder share the same knowledge map. The contributor's discipline is restraint: change as little as possible, respect every rule in Step 6, and prove it still works.

---

## Step C1: Locate the Change Surface

**Goal:** Project the desired change onto the dependency graph from Step 2.

**Actions:**
1. Name the user's intent in one sentence ("add endpoint X", "fix bug in flow Y", "support format Z").
2. Identify which flow (Step 4) the change lives in, and trace it to the exact components.
3. Mark every unit the change touches on the Step 2 graph.

**Key Questions:**
- Which layer does this belong in — a leaf (logic), infrastructure, or an app shell?
- Does the change ripple *upward* (leaf changes force app changes) or stay local?

**Decision Point:** "This change touches [units]; it lives in flow [name] at [file:line]."

---

## Step C2: Run the Invariant Gauntlet

**Goal:** Check the proposed change against every invariant from Step 6 *before* writing code.

**Checklist (instantiate from Step 6's invariant table):**
- [ ] **Mirrored implementations:** If the change touches a mirrored component (e.g., two server runtimes), is it applied to *both*?
- [ ] **Build order:** Does the change require artifacts to be rebuilt in a specific order? Does my workflow honor it?
- [ ] **Boundary bridges:** Does the change cross a fragile boundary (shadow DOM, FFI, serialization)? Is the bridge still intact?
- [ ] **Shared contracts:** If the change alters a contract from Step 5, are *all* parties to that contract updated together?
- [ ] **Conventions:** Does the change follow the naming, structure, and style the repo already uses (Tailwind `@source` paths, theme tokens, error formats, etc.)?

**Anti-Pattern to Avoid:**
```
// BAD: changed the Bun server endpoint, shipped, forgot the Pi server mirror.
//      Pi users get a 404 — fails silently for everyone not testing Pi.

// GOOD: changed BOTH packages/server/*.ts AND apps/pi-extension/server/*.ts,
//       (or the vendored source + re-ran vendor.sh), then typechecked both.
```

**Decision Point:** "This change respects all invariants; the riskiest is [X], which I handled by [action]."

---

## Step C3: Find the Smallest Safe Change

**Goal:** Reduce the change to its minimal form.

**Thinking Framework:**
- "What is the smallest diff that satisfies the intent and breaks nothing?"
- Prefer extending a seam (Step 6) over modifying a core type.
- Prefer adding a new case over rewriting an existing branch.
- If the change needs a new contract, design it to be *additive* (optional field, new endpoint) rather than breaking.

**Actions:**
1. Draft the change as a diff in your head; count the files touched.
2. If it touches a core noun (Step 5), ask whether a seam could absorb it instead.
3. Confirm the change is additive where possible.

**Decision Point:** "The minimal change is [N files]; it is additive/breaking because [reason]."

---

## Step C4: Verify

**Goal:** Prove the change works and breaks nothing, using the project's own tooling.

**Checklist:**
- [ ] Run the project's typecheck — in the *correct order* if one is mandated (e.g., vendor step → leaves → infra → apps).
- [ ] Run the project's build — in the *correct order* (e.g., build the dependency artifact before the consumer that copies it).
- [ ] Run existing tests; add a test for the new behavior if the repo has a test culture.
- [ ] Manually exercise the affected flow (Step 4) end-to-end.
- [ ] Re-read the diff against the Step 6 invariant checklist one final time.

**Decision Point:** "Typecheck, build, and tests pass; I manually verified flow [name]."

---

## Step C5: PR Readiness

**Checklist:**
- [ ] The change matches the repo's contribution conventions (read `CONTRIBUTING.md` / `AGENTS.md`).
- [ ] Commit style matches the repo's history.
- [ ] The PR description states the intent, the change surface (which units), and which invariants were considered.
- [ ] No unrelated files / formatting churn.
- [ ] Docs updated if a contract or user-facing behavior changed.

**Deliverable:** A minimal, invariant-respecting, verified change plus a PR description that proves you understood the system — not just the line you edited.

---

## Worked example (Plannotator): "Add a new `/api/foo` endpoint"

1. **Change surface:** lives in the server infrastructure layer → touches `packages/server/` **and** `apps/pi-extension/server/` (mirrored runtimes).
2. **Invariant gauntlet:** the dual-runtime mirror is the riskiest — must add the route to both the Bun server and the Pi `node:http` server (or to the vendored source, then re-run `vendor.sh`).
3. **Smallest change:** add the route handler to the shared handler module if one exists, so both runtimes pick it up; otherwise add it twice.
4. **Verify:** run typecheck with the `vendor.sh`-first order; build `apps/review` before `build:hook`; exercise the endpoint under both runtimes.
5. **PR:** note "added `/api/foo` to both server runtimes; respects the mirror invariant."
