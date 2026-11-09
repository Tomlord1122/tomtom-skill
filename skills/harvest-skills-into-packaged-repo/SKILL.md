---
name: harvest-skills-into-packaged-repo
description: Select reusable installed agent skills and add them to a packaged skill repo that keeps each skill directory beside a matching zip. Use when the user asks to harvest, copy, or publish Cometline or agent skills into a skill collection, then commit and push only the new packs. Do not use for installing one family with the skills CLI, installing a marketplace plugin into Cometline, or authoring a new skill from a past workflow.
tags:
  - skills
  - packaging
  - git
metadata:
  cometline:
    origin: self-improvement
---

# Harvest skills into a packaged repo

Installed skills and a distribution repo are different trees. Copy only skills that are reusable, not already packaged, and free of private content. A large diff is not a reason to add every skill.

## 1. Inventory both trees before choosing

1. List installed skill directories that contain `SKILL.md`. Check both the agent skill root and the Cometline skill root. If one is a symlink to the other, treat them as one tree and do not double-count.
2. Skip builtin skills and skill drafts.
3. List skill directories already in the destination repo. A name match is already packaged. Do not refresh it unless the user asked to update existing packs.
4. Read the destination layout from its agent guide and from one existing zip, not from memory. Note whether the zip stores a top-level `{skill-name}/` folder and sits beside the directory as `{skill-name}.zip`.
5. Check git status, remote, and current branch before copying. Leave unrelated untracked directories alone.

## 2. Judge reuse, then read the body

A description is not enough. Keep a skill only when all of these are true:

- It is a multi-step workflow with a specific trigger, not a one-off UI fix, app-specific note, or private machine path.
- It is not a near-duplicate of a skill already in the destination repo.
- Its body is the procedure. A file whose whole body is "load this other skill" is a stub. Skip it; the missing primitive is not in the copy.
- A secret scan of the skill files finds no real credentials, user-private paths, or local absolute home paths. A word like `API_KEY` inside a generic troubleshooting sentence is not a secret. A real token, password, or private path is. Skip that skill and say why. Do not rewrite the body to strip it.

Prefer skills the user actually uses. Do not add every candidate. If none qualify, do not commit. Report why.

## 3. Copy and zip to match the existing packs

1. Copy each chosen directory into `skills/{name}/`. Keep auxiliary files. Do not add an empty `scripts/` directory just because a template mentions scripts.
2. Build the zip from the destination `skills/` directory so the archive root is `{name}/`, matching existing archives:

```bash
rm -f "skills/${name}.zip"
(cd skills && zip -r -X "${name}.zip" "${name}" -x '*.DS_Store')
unzip -l "skills/${name}.zip"
```

3. Confirm the zip listing starts with `{name}/` and includes `SKILL.md`. A zip of bare files, or a zip nested inside the skill directory, does not match the pack layout.

## 4. Commit only the new packs and push the existing remote

1. Load the repo's commit convention before committing. Verify `git config user.name` and `git config user.email` when sign-off is required.
2. Stage only the new skill directories and their sibling zips. Do not `git add -A` when unrelated untracked files exist.
3. One signed-off commit is enough for one harvest batch. Split only if the additions are unrelated.
4. Push the current branch to its existing remote. Do not force-push and do not create a remote. If push fails, leave the commit local and report the error.
5. After a successful push, report the skill names, a one-line reason for each, and the commit SHA. Also list the classes you skipped.

## Pitfalls

- Treating `~/.agents/skills` and `~/.cometmind/skills` as two catalogs when one is a symlink double-counts every skill.
- A stub that says "call another skill" looks reusable until you read the body. Copying it publishes a pointer to a skill the reader does not have.
- The destination agent guide may require `scripts/`. Existing packs that have no scripts are the real layout. Do not invent a stub script to satisfy the template.
- Zipping from the skill directory puts files at the archive root. Existing packs store `{name}/SKILL.md`. Build the zip from the parent `skills/` directory.
- `git add -A` in a dirty skill repo commits unrelated untracked trees such as handoff notes. Stage the new directories and zips by path.
---