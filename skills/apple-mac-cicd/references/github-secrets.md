# GitHub Secrets for macOS CI/CD

Configure these in **Settings → Secrets and variables → Actions** on your GitHub repo.

## How to create the P12 for CI

```bash
# Export Developer ID Application cert from Keychain Access → .p12
# Then base64-encode for GitHub secret:
base64 -i certificate.p12 | pbcopy
# Paste into APPLE_DEVELOPER_ID_P12_BASE64 (native) or CSC_LINK (Electron)
```

Generate an app-specific password at [appleid.apple.com](https://appleid.apple.com/account/manage) → Sign-In and Security → App-Specific Passwords.

Find Team ID at [developer.apple.com/account](https://developer.apple.com/account) → Membership details.

## Native Swift stack (Cometrans)

| Secret | Description | Example |
|--------|-------------|---------|
| `APPLE_DEVELOPER_ID_P12_BASE64` | Base64 `.p12` of Developer ID Application cert | (generated) |
| `APPLE_DEVELOPER_ID_P12_PASSWORD` | Passphrase used when exporting `.p12` | `your-p12-password` |
| `KEYCHAIN_PASSWORD` | Random password for ephemeral CI keychain | any strong random string |
| `DEVELOPER_ID_APPLICATION` | Full codesign identity string | `Developer ID Application: Name (TEAMID)` |
| `APPLE_ID` | Apple ID email for notarization | `you@example.com` |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password (not account password) | `xxxx-xxxx-xxxx-xxxx` |
| `APPLE_TEAM_ID` | 10-character team ID | `W8PJ7773T8` |

## Electron stack (Cometode)

| Secret | Description | Example |
|--------|-------------|---------|
| `CSC_LINK` | Base64 `.p12` of Developer ID Application cert | (generated) |
| `CSC_KEY_PASSWORD` | Passphrase for `.p12` | `your-p12-password` |
| `APPLE_ID` | Apple ID email for notarization | `you@example.com` |
| `APPLE_APP_SPECIFIC_PASSWORD` | App-specific password | `xxxx-xxxx-xxxx-xxxx` |
| `APPLE_TEAM_ID` | 10-character team ID | `W8PJ7773T8` |

`GITHUB_TOKEN` is auto-provided by Actions — no manual setup needed.

## Local development env vars

For local signed builds, export the same vars (without base64 for P12 — use the file path instead):

```bash
export DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)"
export APPLE_ID="you@example.com"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
export APPLE_TEAM_ID="TEAMID"
export NOTARIZE=1
```

For Electron local builds, electron-builder reads `CSC_LINK` (file path or base64) and `CSC_KEY_PASSWORD`.

## Security notes

- Never commit `.p12` files or app-specific passwords to the repo
- Rotate app-specific passwords if leaked
- Use separate certificates per app if possible
- CI keychains are ephemeral — destroyed after each job
