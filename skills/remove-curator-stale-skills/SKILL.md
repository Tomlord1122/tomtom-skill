---
name: remove-curator-stale-skills
description: Remove packaged skills the Cometline curator has marked stale, and delete an untracked leftover directory the user names. Use when the user asks to remove outdated skills, clean curator-stale packs, or delete a leftover untracked directory such as handoff. Do not use for refreshing packs that differ, installing or updating a skill, or deleting every skill missing from the local install.
metadata:
  cometline:
    origin: self-improvement
---

# Remove curator-stale skills

A skill that is not installed locally is not outdated. Curator `stale` is the deletion signal. Delete only the intersection of that status and the packaged repo, plus the sibling zip. Leave active skills, uncurated packaged skills, and unrelated untracked files alone unless the user names them.

## 1. Inventory both trees, then stop

1. List skill directories that contain `SKILL.md` in the packaged repo, `~/.cometmind/skills`, and `~/.agents/skills`.
2. If one home path is a symlink to the other, treat them as one install tree.
3. A name present only in the repo is not a deletion candidate. It may be a distribution pack that was never installed here.
4. Check `git status -sb` before deleting. Note untracked directories so they are not swept into the skill commit.

## 2. Read curator status, not prose

1. Open `~/.cometmind/cometmind.db` read-only. The table is `skill_curator_state`. Useful columns are `skill_name`, `origin`, `status`, `pinned`, `last_used_at`, `unused_since`, `archived_at`.
2. Grep of `SKILL.md` for "stale", "outdated", or "deprecated" is not a status. Those words appear inside procedures about indexes, CI, and docs.
3. Query statuses. A missing row means the skill is not curated. Do not delete it for that reason.
4. Delete a packaged skill only when `status` is `stale` and `pinned` is `0`. `active` stays. A pinned row stays even if unused.
5. `stale` skills that are not in the packaged repo live only in the install tree. Do not delete those unless the user asked to clean the install, not the repo.

```bash
python3 << 'PY'
import sqlite3
from pathlib import Path
db = Path.home() / ".cometmind/cometmind.db"
con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
cur = con.cursor()
repo = Path("skills")
repo_names = {p.name for p in repo.iterdir() if p.is_dir() and (p / "SKILL.md").exists()}
rows = cur.execute(
    "SELECT skill_name, status, pinned FROM skill_curator_state WHERE status != 'active'"
).fetchall()
for name, status, pinned in sorted(rows):
    if name in repo_names and pinned == 0:
        print(f"{status}\t{name}")
PY
```

## 3. Confirm the pack is not a hard dependency

1. Search the repo for each candidate name in markdown and manifests.
2. A contrast sentence ("This is not `other-skill`") is not a dependency. A required `load_skill`, install script, or catalog entry that would break is.
3. If the only hits are the skill's own `SKILL.md` and contrast mentions, it is safe to remove.
4. Confirm both `skills/{name}/` and `skills/{name}.zip` exist before `git rm`. This layout stores the directory beside a matching zip. Deleting only the directory leaves a stale archive.

## 4. Delete the pair, commit, and push

1. `git rm -r` each directory and its sibling zip in one command. Do not `rm` tracked files and then forget the zip.
2. Commit only those deletions. Do not stage the untracked directory noted in step 1.
3. Use a chore commit that says the curator marked them stale. Sign the commit the way this repo already does (`git commit -s`).
4. Push the current branch only after the user asked to remove the skills from the published collection, which this cleanup request includes. Confirm `git status` is clean except for the leftover untracked path.

## 5. Delete a named untracked leftover only when asked

1. If the user then names the leftover directory, list its files and run `git ls-files` on it first.
2. An empty `git ls-files` result means it was never committed. `rm -rf` that directory. Do not create a commit for an untracked delete.
3. If `git ls-files` returns paths, stop and treat it as a tracked removal, not a local leftover.

## Pitfalls

- Not installed is not stale. The first inventory will list repo-only skills. Those are distribution packs, not deletion candidates.
- Curator prose is not curator state. "Index is stale" inside a skill is an instruction to the reader, not a mark on the skill.
- A contrast mention is not a dependency. Another skill may name the candidate to say it is a different job. That sentence does not block deletion.
- The zip is part of the pack. `git rm` of the directory alone leaves `skills/{name}.zip` shipping the deleted procedure.
- Do not fold an unrelated untracked directory into the skill commit. Delete it only after the user names it, and only with `rm` when it is untracked.