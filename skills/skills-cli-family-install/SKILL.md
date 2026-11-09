---
name: skills-cli-family-install
description: Install only one skill family from a multi-skill repo with `npx skills add`. Use when the user wants a nested directory, prefix, or family so the CLI loads one group and not the rest of the repo. Do not use for authoring skill triggers, frontmatter tags, or splitting a mindset into skills.
tags:
  - skills
  - cli
  - packaging
metadata:
  cometline:
    origin: self-improvement
---

# Install one skill family with the skills CLI

`npx skills add` filters by skill name or by the directory you point at. A name prefix and a folder nested under `skills/` are not a family filter.

## 1. Read the CLI, then the pack

1. Read the current `skills` README source formats, `--skill`, and Skill Discovery. Do not trust an older mental model of depth.
2. Discovery walks known containers (`skills/`, `.agents/skills/`, and the other agent dirs) up to three levels: `skills/<name>/SKILL.md`, `skills/<category>/<name>/SKILL.md`, and `skills/<category>/<category>/<name>/SKILL.md`. A `SKILL.md` at a shallower level shadows anything nested under it. `--full-depth` also finds skills outside those containers, which means the rest of the repo.
3. `--skill` matches the frontmatter `name`, not the directory path. Listing every name in the family works, but a new sibling is missed until the command is edited.
4. Confirm the pack layout. If the family already lives at `skills/<name>/SKILL.md` beside other skills, moving it under `skills/<family>/<name>/` does not scope `npx skills add <repo>`.

## 2. Make the family the search root

1. Put only that family in its own top-level directory, not under `skills/`:

```text
handoff/t-one/SKILL.md
handoff/t-two/SKILL.md
handoff/README.md
```

2. Keep other skills in the repo's normal `skills/` tree. Do not add a `SKILL.md` on the family directory itself, or it shadows the children.
3. A README in the family directory is not a skill. Use it to record the install command. Do not rewrite a shared agent-operations file just to document one family.
4. Move untracked directories with `mv`, not `git mv`. `git mv` fails with "source directory is empty" when git is not tracking the source.

## 3. Point `add` at that directory

Local check, before any install:

```bash
npx skills add ./handoff --list
```

The list must contain only that family. If other repo skills appear, the path is not the search root.

Published GitHub install uses the tree URL, which becomes the search root:

```bash
npx skills add https://github.com/<owner>/<repo>/tree/<branch>/handoff
```

SSH `git@` URLs have no equivalent path. There is no `--path` flag. Do not use `--full-depth` to "find the family"; it discovers every skill.

The tree URL does not work until that directory is pushed. Do not commit or push unless the user asks.

## Pitfalls

- Nesting under `skills/<family>/` looks like a filter and is not one. Default `add` of the repo still sees those skills, and an extra level can fall outside the depth walk.
- `--skill a b c` is a name list, not a prefix. `t-*` does not select the family.
- `--full-depth` and a root install both load every skill in the repo. That is the opposite of a family install.
- A tree URL against a branch that does not contain the directory yet 404s. Verify with a local `--list` first, and say the remote command waits on push.
- Do not invent a router skill so the CLI installs one entry. Selection is the source path.