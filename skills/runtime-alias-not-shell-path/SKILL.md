---
name: runtime-alias-not-shell-path
description: Keep the @runtime path alias inside file-tool parameters and use a real ~/.cometmind path in the shell. Use when a command, skill, or redirect would mkdir or write @runtime/..., when run_command rejects @runtime, when a literal @runtime directory appears in the workspace, when dumping CLI stdout, or when an external program needs a content file. Do not use for LLM wiki ingest, query, or lint.
tags:
  - cometline
  - paths
metadata:
  cometline:
    origin: self-improvement
---

# Runtime alias is not a shell path

`@runtime` is a path alias understood only by file-tool path parameters. It is not a directory, and the shell does not expand it. `run_command` rejects any command string that contains `@runtime` before the shell runs. The rejection text names the real directories. Do not retry the same command, quote the alias, or strip the `@` and hope the shell will create the mount.

Do not rewrite `@runtime` into a real path inside the command string and leave the alias in the same string. The check is a substring search, not a path parser. `echo @runtime`, a comment, and a heredoc that mentions the alias are all rejected.

## 1. Pick the tool before the path

1. File tools (`read_file`, `write_file`, `edit_file`, `glob`, `grep`, `list_dir`) expand the alias:
   - `@runtime/tmp/...` → `~/.cometmind/agent-tmp/...` (shared read/write, age-purged)
   - `@runtime/tool-output/...` → `~/.cometmind/tool-output/...` (read-only after creation)
   - `@runtime/wiki/...` → `~/.cometmind/wiki/...` (persistent read/write)
2. `list_dir` on `@runtime` lists those mounts. It does not list `~/.cometmind`, and it does not create a folder.
3. `run_command` runs in the workspace root. A command containing `@runtime` returns `OK: false` with `command rejected: @runtime is a file-tool alias and is not expanded by the shell`. Nothing is executed, so this path no longer creates a literal `@runtime` directory. Older sessions, or a shell outside this tool, still can.

## 2. Read full CLI stdout from the spill, not a redirect

Running a command and choosing where its complete stdout lands are different jobs. The shell must run the command. It does not have to know the runtime mount.

1. Run the command with `run_command` and no redirect when the goal is to read the output. Do not put `@runtime` in that command.
2. If the tool result says the output was truncated and gives `@runtime/tool-output/tool_<id>.txt`, `read_file` that alias. `BoundToolOutput` already wrote the full text under `~/.cometmind/tool-output/` once the preview exceeds about 12000 runes. The preview itself is head plus tail, so a middle section can be missing from the tool result while the spill file is complete.
3. Do not `mkdir @runtime/tmp` or `> @runtime/tmp/...` to recover that output. The tool rejects the command. Even if a shell ran it, that write would never reach the spill file.
4. Redirect only when a later step must open a path you chose, or when the tool result has no spill path. Follow section 3. The redirect target must be a real path, with no `@runtime` substring in the command.

## 3. Give an external program a real path

A child process such as `heptabase note save --content-file` is not a file tool. It cannot open `@runtime/...`.

1. `mkdir -p "$HOME/.cometmind/agent-tmp/<task>"` first. A redirect into a missing directory fails before the command runs. Do not treat that shell error as "target not found".
2. Write and pass `"$HOME/.cometmind/agent-tmp/<task>/<file>"`. Use `$HOME` so the path can be quoted. `~` does not expand inside quotes.
3. The same real directories are `$HOME/.cometmind/tool-output` and `$HOME/.cometmind/wiki`. Prefer `agent-tmp` for scratch files a child must create. `tool-output` is where the runtime already spilled command text.
4. Read that file back with `read_file` on the same `$HOME` path, or on `@runtime/tmp/<task>/<file>`. Both are the same directory. Do not look for the file under a workspace `@runtime/` folder.
5. Do not use `~/.cometmind/tmp`. That directory is not the `@runtime/tmp` mount. The mount is `agent-tmp`.
6. Do not write scratch files into the workspace just because the shell is already there. A parent-of-checkouts workspace is not a repo and will keep the junk.
7. Do not pass `@runtime/...` as `--content-file` or any other argument the child will open. The parent `run_command` rejects the whole string before the child starts.

## 4. If a literal `@runtime` directory exists

1. Treat `<workspace>/@runtime` as a mistaken shell write from before the guard, or from a shell that did not go through `run_command`. It is not the runtime store. Compare it with `~/.cometmind/agent-tmp` before assuming the data is missing from the real mount.
2. Do not delete it until the user asks. After they ask, remove only that literal directory. Do not touch `~/.cometmind`.
3. Find the skill or command that taught the shell path. A concrete `mkdir @runtime/...` in a loaded skill is now a command `run_command` will reject, and the agent may still copy it. Replace that snippet with the `$HOME/.cometmind/agent-tmp/...` form, or with a file-tool `@runtime/tmp/...` path when no shell redirect is required. A skill that only says "write stdout to a file" still lets the agent invent `@runtime/tmp` in the shell. Name the real directory, or tell it to read the `@runtime/tool-output` spill instead.

## Pitfalls

- A rejection is not a missing directory. Change the command to a `$HOME/.cometmind/...` path, or drop the redirect and `read_file` the spill alias. Do not `mkdir -p @runtime` again.
- Coding policy, mount docs, and the `run_command` description all say the shell does not expand `@runtime`. A skill that shows the alias inside a bash fence still gets copied, then rejected. Fix the skill; do not rely on the policy line alone.
- Large CLI output is already on disk when the tool result names `@runtime/tool-output/tool_<id>.txt`. Redirecting again is unnecessary, and a redirect that still contains `@runtime` never runs.
- `@runtime/tmp` is `~/.cometmind/agent-tmp`, not `~/.cometmind/tmp`. Writing the wrong real directory looks like the mount is empty.
- `@runtime/tool-output` is read-only through file tools. Do not use it as a scratch dump you create. Reading a spill file from there is the intended path.
- Bare `@runtime` is not a writable mount root. File tools reject unknown mounts such as `@runtime/cometline-settings.json`.
- Skills under `~/.cometmind/skills` cannot be patched with `edit_file` (`path escapes workspace`). Update a self-improvement skill with `write_skill` and `overwrite=true`. Do not rewrite a skill whose origin is not self-improvement.