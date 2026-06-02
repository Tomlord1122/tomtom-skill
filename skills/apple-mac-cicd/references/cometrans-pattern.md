# Cometrans Native Release Pattern

Reference: `cometrans/` in this workspace.

## Build pipeline

`build_dmg.sh` is the single entry point for local and CI builds:

1. `swift test` (skippable with `SKIP_TESTS=1`)
2. `swift build -c release`
3. Assemble `Cometrans.app` with generated `Info.plist`
4. `codesign --force --deep --options runtime`
5. Create DMG via `hdiutil create`
6. Optional notarization when `NOTARIZE=1`
7. Write `Cometrans-{version}.dmg.sha256`

## Versioning for Sparkle

```bash
# 1.6.0 → CFBundleVersion 10600
BUILD_NUMBER=$(( major * 10000 + minor * 100 + patch ))
```

Sparkle compares `CFBundleVersion` numerically. Never put semver strings in `CFBundleVersion`.

## Notarization

`scripts/notarize.sh` uses `xcrun notarytool submit --wait` then `xcrun stapler staple`.

Required env vars:
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`

## GitHub Actions workflow

`.github/workflows/release.yml` — three jobs:

| Job | Purpose |
|-----|---------|
| `prepare` | Resolve version from `workflow_dispatch` input, create tag |
| `build` | Import P12, run `./build_dmg.sh`, upload DMG + sha256 |
| `release` | Publish to GitHub Releases via `softprops/action-gh-release` |

Trigger: manual `workflow_dispatch` with version input (e.g. `v1.2.3`).

Runner: `macos-26` with `DEVELOPER_DIR: /Applications/Xcode_26.4.app/Contents/Developer`

## CI (non-release)

`.github/workflows/ci.yml` — `swift build -c release && swift test` on push/PR.

## Secrets (native stack)

| Secret | Used for |
|--------|----------|
| `APPLE_DEVELOPER_ID_P12_BASE64` | Import signing cert in CI |
| `APPLE_DEVELOPER_ID_P12_PASSWORD` | P12 passphrase |
| `KEYCHAIN_PASSWORD` | Ephemeral CI keychain |
| `DEVELOPER_ID_APPLICATION` | Full cert name for codesign |
| `APPLE_ID` | Notarization |
| `APPLE_APP_SPECIFIC_PASSWORD` | Notarization |
| `APPLE_TEAM_ID` | Notarization |

## Auto-update status

Build numbers are Sparkle-ready. Sparkle framework, appcast feed, and EdDSA signing are not yet wired in Cometrans.
