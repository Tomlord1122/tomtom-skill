# Rebuild Track

Use this after Steps 1–6 of the Reverse Architect thinking process are complete. The goal is a **build specification** for your own version of the project — in your preferred tech stack — that preserves the load-bearing walls and freely swaps everything else.

The rebuilder's discipline is honesty about what is essential. A rebuild that copies the original's accidental complexity is just a slower clone. A good rebuild keeps the *promise* (Step 1) and the *essential contracts* (Step 5), and reinvents the rest.

---

## Step R1: Substitution Matrix

**Goal:** For every tech choice from Step 3, decide keep / swap, and record what each swap costs.

**Build the matrix:**

| Concern | Original choice | Your choice | What you gain | What you lose | Load-bearing? |
|---------|----------------|-------------|---------------|---------------|---------------|
| UI rendering | … | … | … | … | from Step 3 |
| Parsing | … | … | … | … | … |
| Transport/server | … | … | … | … | … |
| … | … | … | … | … | … |

**Rules:**
- A **load-bearing** choice (Step 3) can still be swapped, but you must replace its *property*, not just the library. (E.g., if the original's diff library gives you semantic word-level diffing, your substitute must too — or the promise degrades.)
- A **swappable** choice can be replaced freely; record the swap and move on.
- If you cannot name what a library does for the promise, you do not yet understand Step 3 — go back.

**Decision Point:** "Every concern has a chosen technology; for each load-bearing swap I can name the property I must preserve."

---

## Step R2: Parity Checklist from Essential Contracts

**Goal:** Turn Step 5's essential contracts into a concrete list of things your version must reproduce.

**Actions:**
1. Copy every **essential** contract from Step 5 (core types, load-bearing API/protocol surfaces).
2. For each, write the parity requirement in your stack's terms.
3. Mark **incidental** contracts as "redesign freely."

| Essential contract (original) | Parity requirement (your version) |
|-------------------------------|-----------------------------------|
| Core type `X` with fields a,b,c | Your type must carry semantically equivalent a,b,c |
| Protocol `Y` (e.g., stdout decision format) | Your version must emit the *same* protocol if it integrates with the same external system |

**Critical insight:** Some contracts are with *external systems you do not control* (e.g., an agent's hook protocol). Those are **non-negotiable** — you must match them byte-for-byte to integrate. Internal contracts are yours to redesign.

**Decision Point:** "I have a parity checklist; I know which contracts are externally fixed (must match exactly) vs. internal (free to redesign)."

---

## Step R3: Strip to the Load-Bearing Walls

**Goal:** Separate essential complexity (keep) from accidental complexity (discard).

**Thinking Framework:**
- "Does this component serve the promise (Step 1), or does it serve a constraint the original had that I don't?"
- Original constraints that may be accidental for *you*: legacy compatibility, multi-platform support you don't need, performance optimizations for scale you won't hit, plugin systems for integrations you won't build.
- "If I delete this, does the promise still hold?" If yes → it's accidental for your version.

**Actions:**
1. Walk the Step 2 unit list; for each, decide keep / drop / simplify.
2. Explicitly list what you are dropping and why it was accidental complexity *for your goals*.
3. Re-state the promise and confirm the stripped-down design still delivers it.

**Decision Point:** "My version keeps [essential units]; I am dropping [list] because they served constraints I don't have."

**Example (Plannotator):** A personal rebuild that only targets one agent can drop the **dual-runtime mirror** (Bun + Pi), the **multi-agent provider registry**, and most of the **12+ plugin integrations** — all accidental complexity for a single-target tool. What it *cannot* drop: the annotation data model, the markdown-to-blocks rendering, the review UI, and the agent's decision protocol — those are the load-bearing walls.

---

## Step R4: Sequence the Build (Leaves First)

**Goal:** Order your implementation to mirror the dependency graph from Step 2 — build leaves before the things that depend on them.

**Thinking Framework:**
```
Phase 1: Pure-logic leaves    — data types, parsing, storage. No UI, no server. Unit-testable.
Phase 2: One core flow        — wire a single flow (Step 4) end-to-end, thinnest possible.
Phase 3: The promise, minimal — make the one essential outcome work, ugly but real.
Phase 4: Breadth              — add remaining flows, polish, swap in nicer UI.
```

**Actions:**
1. List your build phases, each delivering something runnable.
2. Phase 1 = the leaves from Step 2 (e.g., the data model + parser).
3. Phase 2–3 = the single most important flow (Step 4) end-to-end, proving the promise.
4. Defer everything in the "dropped/accidental" list until the promise is demonstrably met.

**Decision Point:** "I have a phased plan; Phase 3 delivers the promise; everything after is breadth."

---

## Step R5: The Build Spec Deliverable

Produce a document containing:

1. **Restated promise** (Step 1) — what your version must do.
2. **Substitution matrix** (R1) — your stack vs. the original's.
3. **Parity checklist** (R2) — essential contracts, marked external-fixed vs. internal.
4. **Strip list** (R3) — what you're dropping and why it's accidental.
5. **Phased build plan** (R4) — leaves-first, promise by Phase 3.
6. **Load-bearing-walls statement** — the one sentence that defines what must survive the rebuild.

**Deliverable:** A spec a developer (or agent) can execute to build a faithful-but-personal version — one that preserves the essential value and reflects the builder's own taste in everything else.

---

## Anti-patterns for rebuilds

- **Cargo-culting structure:** copying the original's package boundaries when your scope doesn't need them.
- **Premature breadth:** building all flows before proving the one promise (Step 1) works.
- **Breaking external contracts:** redesigning a protocol that an external system depends on — it will simply fail to integrate.
- **Keeping accidental complexity:** porting the original's multi-platform / legacy / scale machinery into a personal project that has none of those constraints.
