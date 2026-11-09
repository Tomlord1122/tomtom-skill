---
name: plugin-skill-into-cometline
description: Install a Claude Code, Codex, or Cursor marketplace plugin skill into Cometline and finish its local command installer. Use when the user asks to install an agent plugin, marketplace plugin, or GitHub tool into Cometline and the README only documents /plugin marketplace add, codex plugin marketplace, or a host plugin store. Also use when that installer leaves a CLI in place but setup fails because TinyTeX tlmgr must update itself before packages install. Do not use for scoping one family inside a multi-skill repo you already know how to add, refreshing an already-installed skill, or connecting a hosted MCP account the user did not ask for.
tags:
  - skills
  - cli
  - cometline
  - install
metadata:
  cometline:
    origin: self-improvement
---

# Install a host plugin skill into Cometline

Claude Code, Codex, and Cursor marketplace commands are not Cometline commands. Cometline loads `SKILL.md` trees. The skill install does not install the command the skill runs.

## 1. Install only the skill the user named

1. Read the plugin repo layout. The skill is often `plugins/<plugin>/skills/<name>/`, not a top-level `skills/` directory. That path is outside the default container walk, so a root `npx skills add <owner>/<repo>` can miss it.
2. Scope the add with the tree URL. Follow `skills-cli-family-install`: `--list` first, and the list must contain only the skill the user asked for.

```bash
npx skills add https://github.com/<owner>/<repo>/tree/<branch>/plugins/<plugin>/skills/<name> --list
npx skills add https://github.com/<owner>/<repo>/tree/<branch>/plugins/<plugin>/skills/<name> --skill <name> -g -y
```

3. `-g` writes `~/.agents/skills/<name>`. Cometline already scans that directory and `~/.cometmind/skills`. A missing folder under `~/.cometmind/skills` is not a failed install. Do not copy or symlink it there.
4. The current chat's skill index can stay stale after the add. Check the files on disk. A new chat loads the skill. Do not treat a missing `load_skill` in this chat as failure.
5. A plugin folder may also ship MCP or OAuth config. Do not import that unless the user asked to connect the account. The skill tree is enough for a local command.

## 2. Run the skill's installer, not the host marketplace

1. Read the installed `SKILL.md` and its `scripts/`. The command is often missing until that script runs. `doctor` is the readiness check, not the installer.
2. If the user asked to install the product, that is the agreement to run the installer. Say what it will download before the long command (Python tool install, render engine, TeX, fonts). If they only asked what the repo is, ask once before a multi-hundred-megabyte install.
3. Run the script from the installed skill folder so it can find its sibling scripts. On macOS and Linux that is `scripts/install.sh`. Set `UV_NO_MODIFY_PATH=1` so the agent does not rewrite the user's shell profile.

```bash
UV_NO_MODIFY_PATH=1 bash ~/.agents/skills/<name>/scripts/install.sh
```

4. The script can exit non-zero after the command binary is already installed, because it then runs setup and treats a setup failure as failure of the whole script. Check `~/.local/bin/<command>` before assuming the install did not happen.
5. The agent shell may not have `~/.local/bin` on `PATH`. Prefix it before `doctor` or `setup`:

```bash
export PATH="$HOME/.local/bin:$PATH"
<command> doctor
```

6. Optional keys, Blender, or a browser runtime are not required when `doctor` says ready and marks them optional. Never ask the user to paste an API key into chat. If a key is needed, the user enters it in their own terminal.

## 3. If TeX packages fail, update tlmgr, then retry setup only

A fresh TinyTeX can refuse every package install until its package manager updates itself. The tool error is often truncated to `te --self` plus a link to `update-tlmgr-latest.sh`. That is a stale `tlmgr`, not a missing binary and not a reason to reinstall the command.

1. Find the TinyTeX the installer just wrote. The setup log prints the directory. On macOS it is `~/Library/Application Support/<app>/TinyTeX`, and the binary is `bin/universal-darwin/tlmgr`.
2. Update that install's tlmgr, not a system TeX:

```bash
"$HOME/Library/Application Support/<app>/TinyTeX/bin/universal-darwin/tlmgr" update --self
```

3. Retry only setup, not `install.sh`:

```bash
export PATH="$HOME/.local/bin:$PATH"
<command> setup
<command> doctor
```

4. Repeating setup before `tlmgr update --self` fails the same way. After the self-update, setup installs the missing packages and can run its test render.

## Pitfalls

- `/plugin marketplace add` and `codex plugin marketplace add` do not install anything into Cometline. They are host commands.
- A green skill install is not a ready command. The skill's installer and `doctor` are the readiness path.
- `install.sh` exiting 1 does not mean the binary is missing. Read the last step. If only setup failed, fix that step and rerun setup.
- Do not reinstall TinyTeX or the whole tool when tlmgr says to update itself. `tlmgr update --self` on that TinyTeX, then setup again.
- Do not put narration or other API keys in the chat. The setup command that reads a hidden key belongs in the user's terminal.
- A skill line that says "without a shell, use Claude Code or Codex" does not apply in Cometline. Cometline has a shell. The marketplace docs still do not.