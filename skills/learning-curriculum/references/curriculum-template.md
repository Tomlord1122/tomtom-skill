# Curriculum file templates

Use these shapes when filling stubs from `scaffold-curriculum.sh`. Replace bracketed text. Keep snippets under ~20 lines.

---

## README.md

```markdown
# Learning path

For a [audience] who will **rebuild this service from scratch**.

## Outcome

When you finish: [two bullets — capability + habit].

This repo is the **answer key**. Try the rebuild step before peeking.

## Order

| # | File | What you learn |
|---|---|---|
| 0 | [00-mindset.md](./00-mindset.md) | … |
| N | [NN-rebuild.md](./NN-rebuild.md) | Day-by-day rebuild |

Chapters 0–K are **tools**. The last chapter is when you **use them**.
```

---

## Tool chapter

```markdown
# N. [Topic]

Pain: [one sentence, no library name].

## How this repo does it

[Short snippet from a real file. Cite path.]

## What not to do

- [Mistake newbies will make]
- [Flaw in *this* repo, if any]

## Exercise

[They produce or point at something without memorizing the tree.]
```

---

## Rebuild chapter

```markdown
# N. Rebuild this service from scratch

Rule for every slice:

    contract → generate → add 1 method to the caller interface
      → repo + cheapest DB fake → service + mock repo
      → handler + mock service → pass request ctx → tests green

## Domain a clone must hit

- [invariant]
- [HTTP mapping that people guess wrong]

## Phase A — skeleton
**Learn first:** [link]
Checklist:
- [ ] …

## Phase E — first write path
(same shape)

## When you are done

Fine differences: [list]. Drift: [SQL in handlers, Background() in handlers, …].
```
