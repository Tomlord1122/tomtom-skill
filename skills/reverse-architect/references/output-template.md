# Knowledge Map Output Template

Fill this skeleton in as you complete Steps 1–6 of the Reverse Architect thinking process. One idea per section. ASCII-diagram-first. Concrete before abstract. Cite `file:line` for every flow hop and contract. Name the blind spots explicitly.

---

```markdown
# [Project Name] — Architecture Knowledge Map

## 1. Purpose (The Pain & The Promise)

> One sentence, no library names: "This exists so that [person] does not have to
> [painful thing], and it succeeds if and only if [the promise]."

- **Who suffers without it:** …
- **The one promise:** … (the thing that, if removed, makes the project pointless)

## 2. Topography (Boundaries & Dependency Graph)

ASCII graph, ordered leaves → roots:

```
[pure-logic leaves]  →  [shared infrastructure]  →  [app shells]  →  [deployables]
```

| Unit | Path | Single Responsibility | Internal deps |
|------|------|----------------------|---------------|
| … | … | … | … |

- **Load-bearing boundary:** [unit] — exists to isolate [responsibility]; merging it with
  [other unit] would [consequence].
- **Accidental boundaries (if any):** …

## 3. Tech Stack by Concern

| Concern | Library | Why this one | Load-bearing? | Plausible substitute |
|---------|---------|--------------|---------------|----------------------|
| UI rendering | … | … | yes/no | … |
| Parsing | … | … | … | … |
| Persistence | … | … | … | … |
| Transport/server | … | … | … | … |
| Build/packaging | … | … | … | … |

- **Load-bearing choices:** [list] — directly enable the promise.
- **Swappable choices:** [list] — incidental.

## 4. Core Flows (Data in Motion)

For each primary flow, one ASCII sequence diagram + a hop list with `file:line`.

### Flow A: [name]

```
Trigger → receiver → parse/validate → transform → storage/state → render/return → loop closes
```

1. **Trigger:** … (`file:line`)
2. **Receiver:** … (`file:line`)
3. **Transform:** … (`file:line`)
4. **Rest (storage/state):** … (`file:line`)
5. **Return path:** … (`file:line`)

- **Blind spots / what is lost:** …

### Flow B: [name]
… (repeat)

## 5. Data Model & Contracts

### Core Nouns

| Type | Defined in | Key fields | Appears in flows |
|------|-----------|-----------|------------------|
| … | `file:line` | … | A, B |

### Contracts (boundaries that must agree)

| Contract | Form | Between | Essential? |
|----------|------|---------|------------|
| … | HTTP endpoint / stdout protocol / IPC / file format | A ↔ B | yes/no |

- **Load-bearing contracts:** [list] — a rebuild must honor these.
- **Incidental contracts:** [list] — free to redesign.

## 6. Seams & Invariants

### Seams (designed extension points)

| Seam | How to extend it |
|------|------------------|
| … | … |

### Invariants (rules enforced by convention, not the compiler)

| Invariant | Consequence if broken | Fails silently or loudly? | Components constrained |
|-----------|----------------------|---------------------------|------------------------|
| … | … | … | … |

## 7. [Contribution | Rebuild] Track Deliverable

→ See the track appendix (`contribution-track.md` or `rebuild-track.md`).

## Load-Bearing Walls (The Payoff)

> "The essential complexity of this project is [X] — that is what any version must
> preserve. Everything else ([list]) is a swappable implementation choice."
```

---

## Presentation principles

1. **Top-down, not bottom-up** — purpose before mechanics, always.
2. **One diagram, one thesis** — if a diagram shows two things, split it.
3. **Concrete before abstract** — a real `file:line` hop before the general pattern.
4. **Name the blind spots** — say what you *cannot* know from the code, not just what you can.
5. **The load-bearing-walls statement is the punchline** — it serves both tracks at once.
