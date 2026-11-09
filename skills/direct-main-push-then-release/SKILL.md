---
name: direct-main-push-then-release
description: >-
  Commit on the default branch, push it, and start the existing GitHub release workflow without inventing a version. Use when the user asks to commit on main and push directly, then trigger a release with gh workflow. Do not use for an integration-branch PR, commit-message style, or waiting until the release build finishes.
metadata:
  cometline:
    origin: self-improvement
---

# Direct main push, then dispatch release

The user wants the commit on the default branch and a release started from the workflow that already owns tagging. Do not open a PR, do not create the version tag locally, and do not pass a version unless they named one.

## Steps

1. Confirm the checkout, branch, and that the dirty files are only the change they asked to ship:

   ```bash
   git rev-parse --show-toplevel
   git status
   git branch --show-current
   git diff
   ```

   If the workspace root is not the repo, pass `-C <repo>` on every git command. Stop if the branch is not the default branch they named, or if unrelated dirty files are present. Do not switch branches or stash those files to force the push.

2. Read the release workflow before committing. Find `on:` in `.github/workflows/*release*`. This class of workflow has both:

   - `push: tags: ['v*']`
   - `workflow_dispatch` with an optional `version` input

   When `version` is empty, the job itself finds the latest `v*` tag and bumps patch (with its own rollover rules), then creates and pushes the annotated tag. Dispatching with no input is the correct trigger. Do not compute `vX.Y.Z` and pass it, and do not `git tag` locally. A local tag plus a workflow bump can race or skip the run (`skip=true` when HEAD already has a tag).

3. Commit only the intended paths with the repo's signed-off form, then push that branch:

   ```bash
   git add <paths>
   git commit -s -m "type(component): message" -m "Body."
   git push origin HEAD
   ```

   A remote note that a pull-request rule was bypassed is a successful direct push, not a failure. Do not open a follow-up PR to "satisfy" that rule after the user asked to push directly.

4. Dispatch the workflow by file or by the `name:` field, on the branch just pushed:

   ```bash
   gh workflow run release.yml --ref main
   ```

   If the file is not registered, use the workflow `name:` (`gh workflow run "Release macOS" --ref main`). Do not add `-f version=...` when the user did not name a version.

5. Confirm a new run exists, then stop. Do not watch the build.

   ```bash
   gh run list --workflow=release.yml --limit 3
   ```

   The new row should be `workflow_dispatch` on the branch you pushed, with status `queued` or `in_progress`. Report the run URL. The tag does not exist until the workflow's resolve step creates it, so do not poll `git tag` or `gh release view` as proof the trigger worked.

## Pitfalls

- Pushing `main` does not start this release. Tag push and `workflow_dispatch` are the only triggers. A green `git push` with no dispatch leaves no release.
- Inventing the next version from `git tag -l 'v*' | head` and passing it as `version` duplicates logic the workflow already owns, including patch rollover. Empty input is the contract.
- `gh workflow run` can return before the run is listed. A short sleep, then `gh run list --workflow=release.yml --limit 3`, is enough to confirm the dispatch. An empty list immediately after the command is not a failed trigger.
- Do not treat "trigger a release" as "wait for notarization". The user asked to start the workflow. Watching a multi-minute macOS release is a different task.
- A branch-protection bypass message on push is expected when the user explicitly asked to push to the default branch. Do not revert, force-push, or open a PR to undo a push they requested.
- `gh run list --branch main` mixes CI pushes with releases. Filter by the release workflow file so an older successful release is not reported as this dispatch.