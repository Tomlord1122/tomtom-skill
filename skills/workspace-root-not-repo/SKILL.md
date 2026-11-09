---
name: workspace-root-not-repo
description: >-
  Run git and Go from the real checkout and module roots, not from a guessed -C path. Use when git status, git add, git stash, or git commit fails with "not a git repository" or "No local changes to save", or when go test, go build, or gofmt fails with "go.mod file not found". Also use when status paths look like src/ and ../module instead of the nested app and module directories. Do not use for commit message style, splitting commits, or waiting on CI.
tags:
  - git
  - go
metadata:
  cometline:
    origin: self-improvement
---

# Find the real git root and Go module before every command

A new shell starts at the agent workspace root. That root is sometimes above the checkout, and sometimes it already is the git toplevel. Guessing `git -C cometline` is wrong in the second case: git still finds the parent `.git` by walking up, so the command looks successful, but every path is relative to the nested app directory.

## 1. Discover the roots in the same command

Do not trust a remembered layout. Print both candidates, then use the toplevel git prints.

```bash
git rev-parse --show-toplevel
git -C cometline rev-parse --show-toplevel
ls go.mod cometline/go.mod cometline/cometmind/go.mod
```

- If `git rev-parse --show-toplevel` already prints the checkout, the shell is at the git root. Do not add `-C cometline`.
- If only `git -C cometline rev-parse --show-toplevel` works, and that path is the checkout (it contains both the desktop app directory and the runtime module), use `-C` on that path.
- If `-C cometline` prints a path ending in `/cometline/cometline`, it entered the nested app directory and walked up to the parent repo. That is the wrong cwd for pathspecs.

Go module root is the directory that contains `go.mod`. In this workspace that is `cometline/cometmind/`, one level under the git root, not the git root itself.

## 2. Read status from that same directory

Pathspecs are relative to the directory git is actually using, which is the `-C` directory when you pass one, otherwise the shell cwd. They are not relative to the workspace root, and they are not relative to the toplevel if `-C` pointed at a subdirectory.

From the real toplevel, status looks like:

```text
 M cometline/src/...
 M cometmind/internal/...
```

From the nested app directory, the same files look like:

```text
 M src/...
 M ../cometmind/internal/...
```

Copy pathspecs from the status you just printed. A command whose pathspecs do not match prints `No local changes to save` or stages nothing. That is a missed path, not an empty tree. Do not checkout, commit, or pop a stash until a second status shows the files you meant to move are actually stashed or staged.

Each tool call starts a new shell at the workspace root. A `cd` in an earlier call does not stick. Put the directory and the git or go command in one invocation.

```bash
cd "$(git rev-parse --show-toplevel)" && git status --short
cd "$(git rev-parse --show-toplevel)" && git add cometline/src/path cometmind/internal/path
cd "$(git rev-parse --show-toplevel)" && git commit -s -m "type(component): message" -m "Body."
```

When the shell is not yet inside the repo, chain from the directory that `rev-parse` accepted:

```bash
cd "$(git -C cometline rev-parse --show-toplevel)" && git status --short
```

Prefer repeated `-m` flags. A shell heredoc inside `git commit -m "$(cat <<'EOF' ...)"` can die with `unexpected EOF while looking for matching` before git runs.

## 3. Go

Run module commands against the directory that contains `go.mod`, in the same invocation.

```bash
go -C cometline/cometmind test ./internal/tools/... -count=1
```

If this Go version has no `-C`:

```bash
cd cometline/cometmind && go test ./internal/tools/... -count=1
```

Package paths are relative to the module. A second `go test` at the workspace root or the git root repeats `go.mod file not found`. Change the directory argument, not the flags.

## Pitfalls

- `git -C` does not mean "the git root". If that relative directory is a nested app folder, git walks up to the parent `.git` and status paths shift to `src/` and `../`. Pathspecs written for the toplevel then match nothing.
- `No local changes to save` on `git stash push -- <paths>` means those pathspecs missed. Fix the directory and copy paths from `git status` in that directory. Checkout stays blocked until the unrelated dirty files are actually stashed.
- `git add` without the right root looks for `.git` at the workspace root and never stages the nested files.
- `go test` at the git root still fails when `go.mod` is one level deeper.
- Leave unrelated dirty files unstaged until the user claims them. Once the user says that leftover is theirs and asks to include it, re-diff that path and give it its own signed-off commit. Do not fold it into the previous commit with `--amend` unless the user asks to rewrite history.