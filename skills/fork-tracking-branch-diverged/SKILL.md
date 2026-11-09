---
name: fork-tracking-branch-diverged
description: >-
  Realign a local upstream-tracking branch when a fork syncer skips it as diverged. Use when sync-forks or a similar script prints that the local tracking branch diverged from upstream, or when a mirror branch is ahead 1 and behind many with no shared history. Do not use for ordinary fast-forward pulls, feature-branch rebases, or when the local-only commits are the user's own work.
metadata:
  cometline:
    origin: self-improvement
---

# Realign a diverged upstream-tracking branch

A tracking branch named like `upstream-<default>` is a mirror of upstream, not a place for local commits. A syncer that only fast-forwards will skip it when histories do not share an ancestor. That skip is intentional. Do not treat it as a broken fetch, and do not force the syncer to merge.

## Steps

1. Read the syncer before touching the repo. Confirm it only updates when `HEAD` is an ancestor of `upstream/<default>` (`merge-base --is-ancestor` then `pull --ff-only`), and that the else branch prints the diverged skip and continues. Note the tracking-branch name it expects (`upstream-<default>`).
2. In that repo, inspect without writing:

   ```bash
   git status -sb
   git remote -v
   git rev-parse HEAD upstream/<default> origin/<default>
   git merge-base --is-ancestor HEAD upstream/<default>; echo $?
   git log --oneline upstream/<default>..HEAD
   git log --oneline --reverse upstream/<default> | head
   ```

3. Classify the divergence before resetting:
   - Same subject on different hashes, no merge-base (exit 1 both ways), local unique commits are an old root the user did not author: upstream rewrote history. Reset is the repair.
   - Unique local commits the user authored, or a dirty worktree: stop. Do not reset or force-push. Ask what to keep.
4. If it is a rewritten mirror and the tree is clean, fetch then hard-reset the tracking branch only:

   ```bash
   git fetch upstream
   git fetch origin
   git reset --hard upstream/<default>
   git status -sb
   git rev-parse HEAD upstream/<default>
   ```

   `upstream` push URL is often `no_push`. Never push to upstream.
5. If `origin/<default>` still points at the discarded root, the next sync will diverge again. Force-push the tracking branch onto the fork's default branch, then verify all three SHAs match:

   ```bash
   git push --force origin <tracking-branch>:<default>
   git fetch origin
   git rev-parse HEAD upstream/<default> origin/<default>
   ```

6. Tell the user the old root hash, the new upstream tip, and that the fork was force-updated. Do not claim other repos were changed.

## Pitfalls

- A status line of `ahead 1, behind N` on a tracking branch is not "one local feature commit." Compare subjects and authors. An initial publish commit that upstream re-cut the next day has the same message and a different hash, and `merge-base` fails both directions.
- `git merge-base` with no output and exit 1 means there is no common ancestor. Do not invent a rebase onto upstream; a mirror should match upstream exactly.
- Resetting the local tracking branch does not move `origin`. Leaving the fork on the old root makes the next sync skip again.
- Force-push only the mirror ref (`upstream-main:main` or equivalent). Do not force-push a branch that contains the user's own commits.
- Do not "fix" the syncer to merge or reset automatically. The skip exists so a diverged mirror is not overwritten on a cron run.