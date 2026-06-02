# Auto-Updater Guide

Two updater stacks depending on app type.

## Electron: electron-updater (Cometode — complete)

### How it works

1. CI publishes GitHub Release with `latest-mac.yml`, `.zip`, `.blockmap`
2. App calls `autoUpdater.checkForUpdatesAndNotify()` on startup
3. electron-updater fetches `latest-mac.yml` from GitHub Releases API
4. Downloads `.zip`, verifies signature, prompts user to install

### Required release assets

| File | Purpose |
|------|---------|
| `latest-mac.yml` | Version manifest with download URL + SHA512 |
| `*.zip` | Update payload (not DMG) |
| `*.blockmap` | Delta update support |
| `*.dmg` | First-time install only |

### electron-builder.yml requirements

```yaml
publish:
  provider: github
  owner: YOUR_GITHUB_USER
  repo: YOUR_REPO
mac:
  target:
    - target: zip
      arch: [arm64]
```

### Main process checklist

- [ ] `import { autoUpdater } from 'electron-updater'`
- [ ] Guard with `if (!is.dev)` — never run in dev
- [ ] `autoUpdater.autoDownload = true`
- [ ] Handle `update-available`, `update-downloaded`, `error` events
- [ ] Periodic check (e.g. every 4 hours)

### Verify auto-update works

1. Install version N from a previous release
2. Push tag `v(N+1)` to trigger CI
3. Wait for GitHub Release
4. Launch installed app — should detect update within seconds

---

## Native: Sparkle (Cometode pattern not applicable; Cometrans pending)

### How it works

1. App has `SUFeedURL` pointing to an appcast XML feed
2. Sparkle checks feed periodically
3. Feed lists latest version with EdDSA-signed enclosure URL
4. Sparkle downloads, verifies signature, installs

### Prerequisites

- Sparkle 2.x via SPM or CocoaPods
- EdDSA key pair (`generate_keys` tool from Sparkle)
- Appcast hosted on GitHub Releases or static URL

### CFBundleVersion rules

Sparkle compares `CFBundleVersion` as integers. Cometrans formula:

```bash
# semver 1.6.0 → CFBundleVersion 10600
BUILD_NUMBER=$(( major * 10000 + minor * 100 + patch ))
```

`CFBundleShortVersionString` holds human-readable semver (e.g. `1.6.0`).

### Info.plist keys

```xml
<key>SUFeedURL</key>
<string>https://github.com/OWNER/REPO/releases/latest/download/appcast.xml</string>
<key>SUPublicEDKey</key>
<string>YOUR_EDDSA_PUBLIC_KEY</string>
```

### CI appcast generation

On each release, CI should:

1. Build and sign `.app` / DMG
2. Run Sparkle's `generate_appcast` or `sign_update` on the zip/dmg
3. Upload appcast.xml alongside release artifacts

Example appcast entry:

```xml
<item>
  <title>Version 1.6.0</title>
  <sparkle:version>10600</sparkle:version>
  <sparkle:shortVersionString>1.6.0</sparkle:shortVersionString>
  <pubDate>Mon, 02 Jun 2026 12:00:00 +0000</pubDate>
  <enclosure
    url="https://github.com/OWNER/REPO/releases/download/v1.6.0/App-1.6.0.zip"
    sparkle:edSignature="SIGNATURE"
    length="12345678"
    type="application/octet-stream" />
</item>
```

### Cometrans current state

- `build_dmg.sh` sets numeric `CFBundleVersion` ✓
- Sparkle framework not integrated yet
- No appcast feed or EdDSA keys yet

To complete Cometrans auto-update:
1. Add Sparkle SPM dependency
2. Integrate `SPUStandardUpdaterController` in app delegate
3. Generate EdDSA keys, store public key in Info.plist
4. Add CI step to generate/sign appcast on release
5. Publish appcast.xml to GitHub Releases
