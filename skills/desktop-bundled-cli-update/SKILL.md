---
name: desktop-bundled-cli-update
description: Update a CLI that is a shim inside a desktop app, not an npm or Homebrew formula. Use when the user asks to update a local CLI, the binary is a shell script that execs an Electron app with ELECTRON_RUN_AS_NODE, or brew and npm do not own the install. Do not use for refreshing an agent skill from a skills-CLI lock, or for upgrading a formula the package manager actually installed.
tags:
  - cli
  - desktop
  - packaging
metadata:
  cometline:
    origin: self-improvement
---

# Update a CLI that ships inside the desktop app

The CLI version follows the desktop app. Do not `npm update` or `brew upgrade` a shim the package manager does not own.

## 1. Prove the CLI is the app, not a package

1. Resolve the binary: `which <cli>` and `file` that path.
2. If it is a shell script, read it. A bundled CLI sets an app executable and a script inside that app, then runs them with `ELECTRON_RUN_AS_NODE=1`.
3. Read the installed app version: `defaults read "<App>.app/Contents/Info" CFBundleShortVersionString`.
4. Run `<cli> --version`. The CLI version and the app version are different fields. Map which desktop release ships the newer CLI from the vendor changelog or help page, not from the shim.
5. `brew info <cask>` saying `Not installed` means Homebrew does not own this copy. Do not `brew install --cask` or `brew upgrade --cask` over `/Applications` just to update it. `npm list -g` empty means the same for npm.

## 2. Let the app updater finish if it is already staged

1. Read `Contents/Resources/app-update.yml` in the installed app. Note `updaterCacheDirName`, `owner`, and `repo`.
2. Look for an in-flight update before downloading anything:
   - `pgrep -lf ShipIt` for that app's bundle id
   - `~/Library/Caches/<updaterCacheDirName>/pending/`
   - `~/Library/Caches/*.ShipIt/update.*/<App>.app`
3. Read `CFBundleShortVersionString` on the staged ShipIt app. If it is the target desktop version, that staged app is the update. Wait for it.
4. Do not quit the app, kill ShipIt, or copy a zip over `/Applications` while ShipIt is running. Poll the installed app version every few seconds until it matches the staged version, then run `<cli> --version` again. The shim path stays the same; the script inside the app changes.
5. A pending temp zip's sha256 will often not match the GitHub release zip hash in the Homebrew cask. That mismatch is a different artifact, not a corrupt update. Do not install the pending zip, and do not treat the mismatch as failure when ShipIt already has the target app staged.

## 3. Confirm the CLI, then the companion skill

1. Success is the installed app version and `<cli> --version` both matching the release you were aiming for, plus the shim still pointing at that app.
2. If an agent skill declares a compatibility range for this CLI, refresh that skill from its lock after the binary is current. Follow `skills-cli-update-installed`. Do not hand-edit the skill to match the new CLI.
3. A new CLI major may delete the skill's `references/` because the detailed guide moved into the CLI (a system-manual command). Missing reference files after a lock-hash change are expected. Confirm the range matches `<cli> --version` before using old recipes.

## Pitfalls

- A Homebrew cask formula is a version hint, not proof this machine installed the app with Homebrew. Upgrading a cask that is `Not installed` can replace a direct install.
- The release zip hash and the updater's pending zip hash are not the same check. Verify the staged app's bundle version.
- Replacing `/Applications/<App>.app` while the app or ShipIt is running races the updater. Waiting for the version flip is the path that completed.
- Old skill recipes are wrong after a CLI interface bump even if the shim still runs. Update the locked skill; do not keep calling commands the new help text removed.