---
name: skills-cli-update-installed
description: Refresh one already-installed agent skill from its skills-CLI lock when the user asks to update that skill to latest. Use when a skill's declared tool range is behind the local CLI, `skills` is not on PATH, or ~/.cometmind/skills is a symlink to ~/.agents/skills. Do not use for installing one family from a multi-skill repo, authoring triggers, or rewriting a skill by hand.
tags:
  - skills
  - cli
  - packaging
metadata:
  cometline:
    origin: self-improvement
---

# Update one installed skill from its lock

The installed folder and `~/.agents/.skill-lock.json` are the source of truth. Do not replace files from a raw GitHub URL when the skills CLI can update the package.

## 1. Find the install, not a second copy

1. Resolve the skill directory. If `~/.cometmind/skills/<name>` is a symlink to `~/.agents/skills/<name>`, that agents path is the only copy. Updating it updates both.
2. Read the lock entry for that name in `~/.agents/.skill-lock.json`. Use `source`, `sourceUrl`, `skillPath`, and `skillFolderHash`. Do not guess the GitHub repo from the skill text.
3. If the skill declares a tool compatibility range, compare it with the installed tool (`<tool> --version`). A mismatch is why the update is needed. The skill range and the package release number are different fields; match the tool to the range.

## 2. Update with the skills CLI

1. `skills` is often not on PATH. Invoke it as `npx --yes skills`. Confirm `update` exists with `npx --yes skills --help` before inventing flags.
2. Update only the named skill, globally, without a scope prompt:

```bash
npx --yes skills update <skill-name> -g -y
```

3. Do not rerun `npx skills add <repo>` unless `update` is unavailable. `add` can pull every skill in that repo. Do not pass `--full-depth`.
4. Do not hand-copy `SKILL.md` or `references/` from raw GitHub. A manual copy misses deleted files, new reference files, and the lock hash.

## 3. Verify the lock and the range

1. Read the skill frontmatter. The compatibility range must match the installed tool's major.minor line.
2. List `references/`. New files from the release must be present. Files the release removed must be gone.
3. Re-read the lock entry. `skillFolderHash` and `updatedAt` must change. `installedAt` stays the original install time.
4. If a symlink was the cometmind install, `ls -l` it again and confirm it still points at the agents path. Do not write a second copy under `~/.cometmind/skills`.

## Pitfalls

- A missing `skills` binary is not a missing CLI. `npx --yes skills` is the working invocation.
- Updating one locked skill is not a family install. `skills-cli-family-install` scopes a first install; this skill refreshes a name already in the lock.
- An empty allow-list style mistake applies here too: do not update every global skill because one was stale. Pass the skill name.
- A symlink means one update. Copying files into the symlink target and also calling `write_skill` creates a divergent second skill.
- The official README may say to re-run `npx skills add`. Prefer `skills update <name> -g -y` so the lock updates and unrelated skills in that repo stay put.