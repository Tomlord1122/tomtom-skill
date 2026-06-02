# Cometode Electron Release Pattern

Reference: `cometode/` in this workspace.

## Stack

- Electron + Svelte + electron-vite
- electron-builder for packaging
- electron-updater for auto-updates
- GitHub Releases as update server

## electron-builder.yml essentials

```yaml
appId: com.tomlord.cometode
mac:
  identity: 'Developer Name (TEAMID)'
  hardenedRuntime: true
  gatekeeperAssess: false
  target:
    - target: dmg
      arch: [arm64]
    - target: zip      # required for electron-updater
      arch: [arm64]
  entitlements: build/entitlements.mac.plist
  entitlementsInherit: build/entitlements.mac.plist
  notarize: true
publish:
  provider: github
  owner: Tomlord1122
  repo: cometode
```

## Entitlements

`build/entitlements.mac.plist` must include Electron runtime needs:
- `com.apple.security.cs.allow-jit`
- `com.apple.security.cs.allow-unsigned-executable-memory`
- `com.apple.security.cs.disable-library-validation`

## Auto-updater (main process)

In `src/main/index.ts`:
- Import `autoUpdater` from `electron-updater`
- Only run when `!is.dev`
- `autoUpdater.autoDownload = true`
- `autoUpdater.autoInstallOnAppQuit = true`
- Check on startup and every 4 hours via `checkForUpdatesAndNotify()`
- Notify user via macOS Notification + tray menu

## GitHub Actions workflow

`.github/workflows/release.yml`:

1. Trigger: `push: tags: ['v*']`
2. Setup Node 20 + pnpm 9 with cache
3. Sync `package.json` version from tag
4. `pnpm install && pnpm build:mac`
5. Publish release with:
   - `dist/*.dmg`
   - `dist/*.zip`
   - `dist/*.blockmap`
   - **`dist/latest-mac.yml`** (required for electron-updater)

## Secrets (Electron stack)

| Secret | Used for |
|--------|----------|
| `CSC_LINK` | Base64-encoded .p12 for codesign |
| `CSC_KEY_PASSWORD` | P12 passphrase |
| `APPLE_ID` | Notarization |
| `APPLE_APP_SPECIFIC_PASSWORD` | Notarization |
| `APPLE_TEAM_ID` | Notarization |
| `GITHUB_TOKEN` | Auto-provided; used for release upload |

## Release flow

```bash
git tag v1.0.1
git push origin v1.0.1
# CI builds, signs, notarizes, creates GitHub Release
```

Installed apps poll GitHub Releases for `latest-mac.yml` and download the `.zip` delta or full update.
