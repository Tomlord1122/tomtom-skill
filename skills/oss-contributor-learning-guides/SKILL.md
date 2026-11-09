---
name: oss-contributor-learning-guides
description: Write a contributor learning guide for one or more local open-source checkouts. Use when the user wants domain, theorems, and a path to a real patch for repos already cloned on disk, or asks for lots of docs, a complete architecture, or deep principles modeled on an existing learning-doc series. Do not use for a single README summary, a systems-observability audit, or notes that belong inside an upstream tracking branch.
tags:
  - documentation
  - open-source
  - learning
metadata:
  cometline:
    origin: self-improvement
---

# Open-source contributor learning guides

Write guides a developer can follow from "why this exists" to a first patch. Ground every path and policy in the checkout. Put the notes outside the checkouts.

Pick the shape from what the user asked for. A moderate path is the short trio in section 3. A request for complete architecture, deep principles, or "write it like this learning-doc series" is the numbered series in section 4. Do not answer the second request with the first shape.

## 1. Survey the trees before choosing a shape

1. List the directory. For each checkout record upstream URL, the branch it tracks, and whether that branch is a mirror (`upstream-main`, `upstream-master`, `upstream-dev`) or the user's own work.
2. Read the README, `CONTRIBUTING.md`, and any in-tree architecture or `AGENTS.md`. Note language, entry binary, and whether external patches are accepted.
3. Map the real layout, not the README table alone: top-level dirs, the package or crate that owns the loop, and where tests sit. `ls` the center; do not recurse the whole tree.
4. Group checkouts that share a domain (runtime and its operator, server and its UI, two implementations of the same loop). The reading order is part of the guide.

Commands that pay off:

```sh
ls -la <open-source-root>
git -C <repo> remote -v
git -C <repo> rev-parse --abbrev-ref HEAD
du -sh <repo>
wc -l <repo>/README.md <repo>/CONTRIBUTING.md
```

Then list the architecture docs and the package/crate/service directories those docs name.

## 2. Choose where the notes live

Write into a notes or learning repo the user already keeps. Do not add guide files to a checkout whose branch only tracks upstream.

Why: a fork syncer fast-forwards those branches, and a monorepo export can rewrite history. Notes committed there are either overwritten or make the branch diverge so sync skips it.

If the user has no notes repo, ask where to put the files. Do not invent a commit on the tracking branch.

## 3. Moderate shape, when they did not cite a series

Use this only when the user wants a learning path and does not point at an existing numbered series, and does not ask for the full architecture plus principles.

| File | Required | Contents |
| --- | --- | --- |
| `README.md` | yes | Pain in one paragraph, vocabulary, architecture tied to directories, the bet or theorem, invariants a patch must protect, what to ignore at first. |
| `learning-path.md` | yes | Ordered steps from running the thing to naming the file a first patch belongs in. Each step has an exercise whose answer is a file, a state, or a policy, not a summary. |
| `contributing.md` | only if upstream accepts patches | Where first patches land, the narrow test command, and traps. Point at upstream `CONTRIBUTING.md`; do not replace it. |
| comparison note | when two trees are the same product shape | One table of where each puts the loop, the permission boundary, and the contribution policy. |

Add an index `README.md` when there is more than one project. The index is the reading order and how the projects relate, not a second copy of each guide.

## 4. Numbered series, when they cite a learning-doc or want depth

If the user points at an existing series, or asks for complete project architecture and deep principles, match that series. A short README plus a learning path is the shape they are rejecting.

### Find the exemplar

A glob for `*learning*` and a grep for `learning-doc` miss a directory named `docs/learning/`. Search the tree the user named, and prune dependency dirs or the hits are package docs.

```sh
find <exemplar-repo> -path '*/node_modules' -prune -o -iname '*learning*' -print
find <exemplar-repo> -path '*/node_modules' -prune -o -name '*.md' -print | rg -i 'learn|guide|arch|overview'
```

Read the index, the first chapter, and the openings of the architecture and data-flow chapters before writing. Extract the moves, not the chapter titles:

- numbered files, each expecting the docs above it, with a prerequisite and a next link
- a glossary that defines a term in plain language the first time it appears
- an index with who it is for, a reading-order table, and a "I want to…" table
- one request walked end to end
- an ownership matrix (owns / must not own) and a one-direction dependency rule
- data flows as ordered steps, a source-file table, and the invariant that flow protects
- a stop that names the file a bug should open

Do not copy the exemplar's chapter list onto a different system. An SDK chapter, a frontend chapter, or a contracts chapter that the target does not have becomes an empty file. Map the moves onto the target's real modules.

### Files that worked for a multi-repo set

Per project, in the notes repo:

| File | Job |
| --- | --- |
| `00-README.md` | Vocabulary, reading order, quick reference. State the tracking branch and that notes do not go in the checkout. |
| `01-nutshell.md` | The pain, the primitives, one call end to end, the processes, what this system is not. |
| `02-architecture.md` | Topography, ownership matrix, dependency direction, the boundary people skip. |
| `03-data-flows.md` | Named flows. Each has steps, a file table, and an invariant. A symptom table at the end maps a bug to a flow and to the wrong repo. |
| `04-principles.md` | The rules the flows protect. A patch can pass a unit test and still break one of these. |
| `05-development.md` | The narrow test, where a change belongs, first patches, an explicit not-yet list, a one-sentence stop condition. |

Add `00-README.md` and `principles.md` at the set root when there is more than one project. The root index is how the projects relate (which one to read first, which pains are different). The comparison note is the shared principles, not a second copy of each nutshell.

For a closed tree (`CONTRIBUTING.md` rejects patches, or the tree is a one-way export): still write 00 through 04. In 05 say read and build, do not send patches, and point at the tree that does take patches. Do not invent a PR workflow.

### After the new series exists

Delete the superseded files (`README.md`, `learning-path.md`, `contributing.md` in those project dirs) once the new links resolve. Leaving both shapes side by side gives two reading paths and stale links.

Why: the user asked to rewrite what was just written. A parallel old guide is the rejected deliverable still on disk.

## 5. Write the domain from the code's contract

1. Open with who suffers if the project does not exist. The first paragraph is the pain, not the feature list.
2. Name the bet the code enforces (level-triggered reconcile, replay-from-history, tasks may run twice, the TUI is a client). Then point at the file or design doc that implements it.
3. Map vocabulary to directories. If a term is only a directory name you have not opened, say so or open it before using it as a fact.
4. Separate core from ecosystem, generated from hand-written, and clients from the runtime. Tell the reader the wrong place to start (dashboard, marketing site, generated client, experimental API).
5. End with invariants. A learning path that never names an invariant does not prepare a contributor.

Open the symbol before you cite it. Cite the file, the type, and the state name. Do not cite a line number. Line numbers move and turn a correct file pointer into a false one.

A tool error is not evidence the symbol is missing. If one search fails with an executor error, search again with the other search tool before dropping the flow.

For a closed tree, state the constraint in the first section.

## 6. Make the path executable

Order, whether it lives in `learning-path.md` or across `01`–`05`:

1. Use the product, or read the user-facing spec, before the implementation.
2. Read the short design doc or state machine before the large source file.
3. One reconcile, one submit path, or one turn of the loop. Name the files.
4. The idempotency, replay, or permission branch. That branch is the product; the happy path is not.
5. The narrow test or `check` command for that slice. Never tell the reader to build the whole workspace first.
6. A first contribution ranked by how welcome it is, then an explicit "not yet" list (schema, event encoding, framework rewrites, auth).
7. A stop condition: the reader can name the file a bug report should open, and which repo if several checkouts could own it.

Exercises ask for a name, a field, or a second-run behavior. "Read the controller" is not an exercise.

## 7. Verify, then stop

1. After writing, list the guide files and extract relative markdown links. Every `](...)` to another guide file must exist.
2. Re-check any command you told the reader to run against the README, Makefile, or `package.json` you actually opened. If you did not open it, point at the doc that owns the command instead of inventing flags.
3. Do not commit the guides unless the user asks.

```sh
find <notes-dir> -name '*.md' | sort
```

Then walk `](...)` links whose target ends in `.md`, resolve them relative to the file, and print any missing path.

## Pitfalls

- A README summary is not a contributor guide. The README is the entry; the guide has to say which file enforces the contract and what a second run does.
- Citing a learning series and still shipping `README.md` + `learning-path.md` + `contributing.md` repeats the rejected shape. Match the series' moves.
- Copying the exemplar's chapter list onto a different architecture produces empty chapters. Copy the reading contract, then map it onto modules you opened.
- Searching only for the string `learning-doc` misses `docs/learning/`. Prune `node_modules` or the search drowns in package docs.
- Leaving the old files next to the new series keeps the rejected path reachable. Delete them after the new links resolve.
- Editing an upstream tracking branch to "leave a note" fights the syncer. The note and the checkout are different repos.
- Starting with the operator, UI, or TUI before the runtime teaches the view and hides the contract. Order the index so the source of truth comes first.
- A contributing page for a repo that does not take patches wastes the reader and will be wrong after the next export. Say "read, do not send patches" and point them at the tree that does take patches.
- Full-workspace builds (`cargo build` with no `-p`, `//:ray_pkg`, `go test ./...` on a multi-service server) are the wrong default. Name the package, crate, or bazel target next to the file.
- Generated roots (workspace `Cargo.toml`, OpenAPI clients, kubebuilder `zz_generated`, CRD yaml) look editable. Tell the reader which command regenerates them and not to hand-edit.
- Inferring a theorem from a directory name produces a confident wrong guide. If the design doc and the source were not opened, do not state the transition table as fact.
- A failed search tool is not a missing symbol. Confirm with a second search before omitting a flow you expected to find.