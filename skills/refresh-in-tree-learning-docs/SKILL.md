---
name: refresh-in-tree-learning-docs
description: Update an existing in-repo learning series so it matches the latest release without rewriting every chapter. Use when the user asks to refresh, catch up, or rewrite a project's learning docs from recent releases and commits, including a request to do it in B2 English. Do not use for writing a new external learning guide, a single README summary, or notes that must stay outside an upstream-tracking checkout.
tags:
  - documentation
  - learning
  - release
metadata:
  cometline:
    origin: self-improvement
---

# Refresh in-tree learning docs

Update the series the project already ships. Match current behavior. Do not rewrite chapters that are still accurate.

## 1. Find the series and the baseline

1. Locate the learning directory by name (`docs/learning/`, a numbered `00-README`, or the path the README and `AGENTS.md` call the reading path). Read the index and the section headings before reading whole files.
2. Record the latest tag and the commit it points at.

```sh
git tag --sort=-creatordate | head
git show -s --format='%H%n%ci%n%s' <latest-tag>
git log -5 --format='%h %ci %s' -- docs/learning
```

3. Find the last commit that actually rewrote the series, not a later formatting or framework bump that only touched a file in that directory. Diff the series from that commit to `HEAD`. If the series has no commits since the last rewrite, the gap is in the code, not in the docs.

Why: a tag that is only a few commits past the previous tag can hide months of behavior that the docs never recorded. The rewrite commit is the baseline, not the previous patch release.

## 2. Pick behavior changes, not every commit

1. List non-merge subjects since the rewrite. Group by conventional-commit scope. Keep `feat` first, then fixes that change a path, a setting name, or a user-visible flow.
2. Ignore format, lint, and one-off UI polish unless a doc names the old component or the old menu.
3. Open the code the surviving subjects name. Confirm the tool name, route, settings key, and file path in the current tree. A commit message is a hint, not the source of truth.

```sh
git log --no-merges --pretty=format:'%h %s' <rewrite>..HEAD
```

If workspace search fails with a bad `rg` binary, run `rg` through the shell, or `git grep`. Do not invent a path because search was empty.

## 3. Patch the chapter that already owns the topic

1. Keep the series outline, vocabulary style, and reading order. Add a row to the index only when a new goal has no existing pointer.
2. Replace the stale sentence in the chapter that already covers that flow. Add a short subsection when the behavior is new and the old section would become misleading if you only appended a clause.
3. Update every copy of a renamed path or menu in the same pass: the flow diagram, the component table, the troubleshooting row, and the extension recipe. A renamed settings page that still appears in one chapter will send the next reader to the old UI.
4. Stamp the index with the tag you checked, and say that later commits can move a path. Do not copy index counts, line numbers, or bundle sizes into the docs.

Why: these series already define terms and point across files. A full rewrite drops those links and rewrites accurate chapters for no gain.

## 4. Keep names exact and prose short

- Keep tool names, API paths, state names, env vars, and file paths as written in code. Format them as code.
- Define a new term once, in the same plain style the series already uses. Do not replace a precise name with a vague everyday word.
- If the user asked for B2 English, apply that only to the sentences you add or replace. Split a new sentence that carries more than one action. Do not restyle the whole series.
- A line-length script counts wrapped Markdown lines, not sentences. Use it as a prompt to reread the new paragraphs. Leave older long lines alone unless you are already editing that sentence.

## 5. Check the edit against the tree

1. Search the series for the old menu label, old component filename, and old tool-registration claim.
2. Confirm every new filename with `find` or `ls` before leaving it in a table. An old panel file can still exist beside the new page.
3. Report which files changed, the tag you checked against, and that the docs were not committed unless the user asked for a commit.

## Pitfalls

- Do not treat "since the latest tag" as the whole gap. Two tags on the same day can still leave the series months behind the rewrite commit.
- Do not document a feature from the commit subject alone. Settings sections get renamed, and slash-command files move, after the feature lands.
- Do not add a second learning guide outside the series when the user asked to update the one inside the project.
- Do not claim the series is certified at a reading level. Say the wording is B2-oriented if asked.