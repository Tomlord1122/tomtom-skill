---
name: post-merge-local-branch-sync
description: >-
  Fast-forward local default and integration branches after a merged PR, then push the integration branch only if it is strictly behind the new merge tip. Use when the user says they merged it and asks to update the local branch. Do not use for diverged fork mirrors, feature-branch rebases, opening the PR, or waiting on CI.
metadata:
  cometline:
    origin: self-improvement
---

# Update local branches after a merge

The user already merged. They want the local checkout on the merge tip, not a new commit and not a reset. Fetch, fast-forward the default branch, fast-forward the integration branch onto that tip, then push the integration branch only when it is a clean ancestor of the merge.

## Steps

1. Inspect before writing. Stay on the current branch until you know the tree and the tracking refs:

   ```bash
   git status -sb
   git branch -vv
   git rev-parse --abbrev-ref HEAD
   ```

   Note untracked and unstaged files. Do not stash, clean, or commit them to make the update look tidy.

2. Fetch the default branch and the integration branch together:

   ```bash
   git fetch origin main dev
   ```

   Use the names this repo actually uses. `main` and `dev` are the usual pair.

3. Fast-forward the default branch from its remote:

   ```bash
   git checkout main
   git pull --ff-only origin main
   git log -1 --oneline
   ```

   The tip should be the merge commit (`Merge pull request #N`). If `--ff-only` refuses, stop. Do not merge, rebase, or reset.

4. Fast-forward the integration branch onto that same tip:

   ```bash
   git checkout dev
   git merge --ff-only origin/main
   git status -sb
   git log -1 --oneline
   ```

   `origin/dev` is often still the pre-merge tip. Merging `origin/dev` leaves the integration branch behind the merge. The source of truth after the user merged is `origin/main`.

5. Read the status line before pushing:

   - `## dev...origin/dev` with no ahead/behind: already aligned. Do not push.
   - `## dev...origin/dev [ahead N]` and `git merge-base --is-ancestor origin/dev HEAD` succeeds: the ahead commits are the merge plus commits already on main. Push:

     ```bash
     git push origin dev
     git status -sb
     ```

   - `ahead` and `behind`, or the ancestor check fails: stop. Do not force-push. Tell the user the two tips.

6. Report both branch tips, the merge subject, and that untracked files were left alone. Do not claim `origin/dev` moved unless the push succeeded.

## Pitfalls

- `git pull` on the integration branch updates it to `origin/<integration>`, which does not contain the merge commit until someone pushes that commit back. Fast-forward from `origin/<default>` first.
- An `ahead N` status after that fast-forward is not local-only work. It is the default branch's commits that the remote integration ref has not received. A normal push is enough. Force-push is for a diverged mirror, not this case.
- `git merge --ff-only` fails when the integration branch has commits that are not on the default branch. That is a stop, not a cue to rebase or merge.
- Checkout and merge do not need a clean untracked file. `git clean` and `git stash` will hide or delete work the user did not ask to ship.
- Do not open a follow-up PR or re-run CI. The user said the PR is merged and asked only to update local branches.