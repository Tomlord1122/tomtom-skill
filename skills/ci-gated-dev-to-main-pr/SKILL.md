---
name: ci-gated-dev-to-main-pr
description: >-
  Commit on the integration branch and open a PR to the default branch only after the checks that actually gate merge are green. Use when the user asks to commit on dev (or another integration branch), open a PR to main, and make sure CI passes. Also use when they say to add "this commit" onto that branch without naming a SHA, or when classic branch protection returns 404 and a ruleset may be the real gate. Do not use for writing commit-message style, splitting commits, or fixing a specific failed job such as generated-client drift.
metadata:
  cometline:
    origin: self-improvement
---

# CI-gated integration-branch PR

A push to the integration branch is not proof that CI ran. Many workflows trigger on `pull_request` and on push only to the default branch. If the user wants the commit on that integration branch and a PR into the default branch, commit there, then open the PR so the required checks exist, then wait until every required check has a terminal success. Skipped path-filtered jobs are not failures.

When a required job fails, fix only that failure, commit on the same integration branch, and push. The open PR picks up the new SHA. Do not open a second PR.

A follow-up push while that PR run is still in progress cancels it when the workflow sets `cancel-in-progress` for `pull_request`. Finish the named fix, then hold unrelated local work until the current head is terminal. One push starts one new run. Two pushes in a row throw away the first run.

## Steps

1. Confirm the working tree, the current branch, and that you are committing only the intended files. Run local format, lint, and typecheck on the touched paths before committing. Local green is necessary but not the CI the user asked for.

   Run Prettier from the package that owns its config, with paths relative to that package:

   ```bash
   pnpm --dir <frontend-package> exec prettier --check <paths>
   ```

   A check started at the repository root against those same relative paths is not a pass. See Pitfalls.

2. If the user says to add "this commit" (or "put this on dev") but names no SHA, read branch and status before looking for a commit to port. When HEAD is already the integration branch and the intended files are modified or untracked, that working tree is the change. Format those paths, commit them on the integration branch, and continue at step 5. Do not scan other branches or the reflog for a SHA. Do not cherry-pick. Do not open a side branch.

3. If the user wants a named existing commit ported onto the integration branch, fetch both branches before cherry-picking:

   ```bash
   git fetch origin <default> <integration>
   git rev-parse origin/<default> origin/<integration>
   git merge-base --is-ancestor <sha> origin/<integration>
   git diff <sha> HEAD -- <touched-paths>
   ```

   If the ancestor check succeeds, or the two tips are the same commit, and the touched paths have no diff, the change is already on the integration branch. Stop. Do not cherry-pick, do not `git commit --allow-empty`, and do not open a PR. Tell the user both branches already have it.

   If a cherry-pick is already in progress and git says it is empty (`nothing to commit`, `cherry-pick --skip`, `all conflicts fixed` with a clean tree), run `git cherry-pick --abort`. An empty cherry-pick means the patch is already in the tree.

4. If you still need to cherry-pick and the working tree has unrelated modifications or untracked files, stash them first so they cannot land in the port commit, then restore them after abort or success:

   ```bash
   git stash push -u -m "wip unrelated before port"
   git cherry-pick <sha>
   git stash pop
   ```

   Pop the stash even when you abort. Do not include those files in the port.

5. When the port is a no-op and the user asks to remove a named junk untracked file and create a PR, delete only that file. Read the remaining diffs. If they are one coherent change, that change is the PR: format those paths, commit them on the integration branch, and continue. Do not commit the junk file. Do not open a PR whose only change is the deletion when other diffs are the real fix.

6. Commit on the integration branch the user named (often `dev`) with the repo's signed commit form, then push that branch. Do not open a side branch when they asked to commit directly on the integration branch.

7. Before treating a push as "CI started", read the workflow triggers. `gh workflow view <name> --yaml` is enough when the workflow file is not in the checkout. Note:
   - `push` branches (often only `main` / `master`)
   - whether `pull_request` is unrestricted
   - path filters and `if:` conditions that skip jobs
   - `concurrency.cancel-in-progress` on `pull_request`. When that is true, a later push to the same PR cancels the run that is still pending.

8. If you need to know what GitHub will block on merge, do not stop at classic branch protection. This returns HTTP 404 `Branch not protected` when the repo uses rulesets instead:

   ```bash
   gh api repos/<owner>/<repo>/branches/<default>/protection
   ```

   List rulesets, then read the active one:

   ```bash
   gh api repos/<owner>/<repo>/rulesets --jq '.[] | {id, name, target, enforcement}'
   gh api repos/<owner>/<repo>/rulesets/<id>
   ```

   Read `rules[].type`. `pull_request` means a PR and reviews are required. No `required_status_checks` rule means CI is not a merge blocker. Still open the PR and wait for the checks the workflow actually runs. A green run is what the user asked to see. Do not skip the watch because status checks are not required. Do not merge to satisfy the review rule.

9. If push to the integration branch does not trigger CI, do not poll `gh run list --branch <integration>` or `gh run list --commit <sha>` and conclude CI passed from an empty or stale list. Those commands return older runs for other SHAs. An empty check-run list and a `pending` combined status with no statuses means no workflow has attached yet.

10. Open the PR from the integration branch into the default branch as soon as the commit is pushed, using the repo's PR title and body style. The PR is what starts `pull_request` CI. Record the PR number from the create output; do not assume the next integer. If `gh pr create` returns HTTP 503, retry the same command. Do not invent a new title or body.

    Draft the body from `git log <default>..HEAD`, not from every commit on the integration branch. A one-commit range is valid even when the default branch has moved ahead of the old integration tip. Do not rebase the integration branch onto the default branch unless the user asked.

11. Watch that PR's checks, not the branch run list:

    ```bash
    gh pr checks <number> --watch
    ```

    Then confirm the terminal state:

    ```bash
    gh pr checks <number>
    ```

    Right after create or a follow-up push, `gh pr checks` can exit with `no checks reported on the '<branch>' branch` even though the PR exists. That means the new SHA has not attached a workflow yet. Confirm the head, then watch again:

    ```bash
    gh pr view <number> --json headRefOid,statusCheckRollup
    ```

    Match `headRefOid` to the SHA you just pushed before trusting any conclusion. A short sleep then `--watch` is fine. Do not fall back to `gh run list --branch`.

12. Treat the gate as passed only when every non-skipped check is `pass` / `success` and none are `pending`, `failing`, or `cancelled`. `skipping` on path-filtered jobs (codegen, other packages, packaging smoke) is expected when those paths did not change. Do not rerun skipped jobs to "make CI complete".

    `cancelled` on the previous head is not a failure of that code and not a pass of the new head. It means a later push superseded the run. Watch the rollup whose `headRefOid` is the tip.

13. If a required job fails, read that job's failed step, not the run summary:

    ```bash
    gh run view <run-id> --job <job-id> --log-failed
    ```

    The job URL from `gh pr checks` ends in the job id. `gh run view --log-failed` refuses while the run is still in progress. Fetch the job log anyway:

    ```bash
    gh api repos/<owner>/<repo>/actions/jobs/<job-id>/logs
    gh api repos/<owner>/<repo>/actions/jobs/<job-id> --jq '{conclusion, steps: [.steps[] | {name, conclusion}]}'
    ```

    Fix only what that log names. Format every path the failed step names, including files the current feature did not edit, when the check is `prettier --check .` or an equivalent whole-package format check. Typecheck or lint passing does not imply formatting passed. Commit that fix on the integration branch with sign-off, and push. The existing PR starts a new run. Repeat the watch. Do not declare the gate passed from an earlier run whose head SHA is older than the tip.

    If the user asks for another change while this run is still pending, make the edit locally and do not push yet. Wait until the current head is terminal, then commit the new change and push once. A second push cancels the run you are waiting on and starts another from scratch.

    Typical failures on this class of PR, and the fix that unblocks them:

    - `gofmt`: the step prints the unformatted path and exits 1 before lint or tests. Run `gofmt -w` on that path, then `gofmt -l` on the module. A struct field that is one character longer than its neighbors is enough to fail. Do not add a lint ignore.
    - `gocritic` `singleCaseSwitch`: rewrite the one-case `switch` to `if`. Do not add a dummy case to silence the linter.
    - Frontend lint `@typescript-eslint/no-unused-vars`: delete the unused binding and the call site that only existed to pass it. A prop removed from a child leaves the parent's each index unused too. Prefix with `_` only when the binding is required by the syntax and cannot be removed.
    - Frontend `Check formatting` / `prettier --check .`: format only the paths the log names, from the package that owns the Prettier config:

      ```bash
      cd <frontend-package> && pnpm exec prettier --write <paths-from-the-log>
      pnpm exec prettier --check <same-paths>
      ```

      Do not format the whole tree. Do not hand-edit generated clients for this failure; that is a different class of job. A local check of the feature files does not prove the package check is green when the log names other files.

14. Report the tip commit SHA, the PR URL, which checks passed, and which jobs skipped because the change did not touch them. If a ruleset requires reviews but not status checks, say that too: green CI is not the same as a mergeable ruleset. Do not merge unless the user asked to merge. If you stopped because the commit was already on both branches, report that and the shared tip instead of a new PR URL.

## Pitfalls

- Branch run history is not this commit's CI. `gh run list --branch dev` prefers recent runs whose titles still say `[main]` or whose `headSha` is the previous commit. Match `headSha` to the commit you just pushed before trusting a conclusion.
- A push-only wait loop wastes the window. If the workflow `on.push.branches` list excludes the integration branch, no amount of sleep will create a run. Open the PR.
- `gh pr checks` exiting 0 while some lines say `pending` is not a pass. Re-read the table. Watch until the required job leaves `pending`.
- `gh pr checks` with no checks is not a failure of the PR and not a pass. Wait until the new head has a rollup, then watch that rollup.
- Skipped is not failed, and skipped is not a substitute for the job that should have run. If the path filter marks the touched package `skipping`, the filter or the checkout is wrong; investigate instead of declaring green.
- A failed required job is not done by reporting the URL. The user asked for CI to pass. Fix the named lint or format issue, push to the same branch, and watch the new run.
- Do not locally rewrite generated clients or unrelated format just to satisfy a job this diff did not trigger. Fix that class only when that job actually fails.
- A 503 from `gh pr create` is a retry, not a reason to change the PR target or open a side branch.
- An empty cherry-pick is not a new commit. `git commit --allow-empty` records a commit that does not contain the fix and still needs a PR. Abort, then prove the SHA is already an ancestor and the touched files match.
- History containing the SHA is not enough if a later commit reverted the file. `git diff <sha> HEAD -- <paths>` must be empty before you say there is nothing to port.
- Stashing unrelated WIP is only safe if you pop it after abort or success. A failed port must not leave the user's other edits in the stash.
- Prettier from the repository root can print `No files matching the pattern` and still say `All matched files use Prettier code style!`. That message means the paths were not found, not that the files are formatted. Run the check from the frontend package, or with `pnpm --dir <frontend-package>`, using paths relative to that package.
- A named junk file the user asked to delete is not the PR. If other unstaged diffs are one coherent fix, commit those and leave the junk file out.
- "Add this commit" with no SHA, while already on the integration branch with a dirty tree, is a local commit. Cherry-picking a guessed SHA from another branch duplicates work or drops the files the user meant.
- A 404 from the branch protection API is not an ungated default branch. Rulesets live on a different endpoint. Read them before you tell the user nothing blocks merge. Missing `required_status_checks` does not cancel the CI watch the user asked for.
- `git log <default>..HEAD` listing only the new commit does not mean the integration branch contains the default branch. Leave the branches as they are and open the PR. Rebase only if the user asks.
- `gh run view --log-failed` on an in-progress run returns no log. The failed job id is already in the checks URL. Read that job's log and step conclusions before the rest of the workflow finishes.
- Pushing a second commit while the PR run is pending cancels that run when `cancel-in-progress` is set for pull requests. Hold the next push until the current head is terminal, unless the push is the fix for a job that already failed.
- A whole-package format check fails on every path it prints, not only the files in the latest feature commit. Formatting the feature files and leaving the logged paths dirty fails the same step again.