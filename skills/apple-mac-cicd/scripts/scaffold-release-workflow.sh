#!/bin/bash

set -euo pipefail

TYPE=""
APP_NAME=""
OUTPUT=".github/workflows/release.yml"

usage() {
  echo "Usage: $0 --type native|electron --app-name Name [--output path]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      TYPE="${2:-}"
      shift 2
      ;;
    --app-name)
      APP_NAME="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

[[ -n "$TYPE" && -n "$APP_NAME" ]] || usage

if [[ "$TYPE" != "native" && "$TYPE" != "electron" ]]; then
  echo "--type must be native or electron" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

echo "Scaffolding $TYPE release workflow to $OUTPUT" >&2

if [[ "$TYPE" == "native" ]]; then
  cat > "$OUTPUT" <<EOF
name: Release

on:
  workflow_dispatch:
    inputs:
      version:
        description: "Release version or tag (for example v1.2.3)"
        required: true
        type: string

permissions:
  contents: write

jobs:
  prepare:
    name: Prepare Release
    runs-on: macos-26
    outputs:
      version: \${{ steps.version.outputs.value }}
      tag: \${{ steps.version.outputs.tag }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Resolve version
        id: version
        run: |
          RELEASE_VERSION="\${{ inputs.version }}"
          APP_VERSION="\${RELEASE_VERSION#v}"
          echo "value=\$APP_VERSION" >> "\$GITHUB_OUTPUT"
          echo "tag=v\$APP_VERSION" >> "\$GITHUB_OUTPUT"

      - name: Ensure tag exists for manual run
        if: \${{ github.event_name == 'workflow_dispatch' }}
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          TAG="\${{ steps.version.outputs.tag }}"
          if git ls-remote --tags origin "\$TAG" | grep -q "\$TAG"; then
            echo "Tag \$TAG already exists, skipping creation."
          else
            git tag -a "\$TAG" -m "Release \${{ steps.version.outputs.value }}"
            git push origin "\$TAG"
          fi

  build:
    name: Build
    needs: prepare
    runs-on: macos-26
    env:
      DEVELOPER_DIR: /Applications/Xcode_26.4.app/Contents/Developer

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Import signing certificate
        env:
          APPLE_DEVELOPER_ID_P12_BASE64: \${{ secrets.APPLE_DEVELOPER_ID_P12_BASE64 }}
          APPLE_DEVELOPER_ID_P12_PASSWORD: \${{ secrets.APPLE_DEVELOPER_ID_P12_PASSWORD }}
          KEYCHAIN_PASSWORD: \${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          if [[ -z "\$APPLE_DEVELOPER_ID_P12_BASE64" ]]; then
            echo "No signing certificate configured. Skipping import."
            exit 0
          fi

          echo "\$APPLE_DEVELOPER_ID_P12_BASE64" | base64 --decode > certificate.p12
          security create-keychain -p "\$KEYCHAIN_PASSWORD" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "\$KEYCHAIN_PASSWORD" build.keychain
          security import certificate.p12 -k build.keychain -P "\$APPLE_DEVELOPER_ID_P12_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security
          security set-key-partition-list -S apple-tool:,apple: -s -k "\$KEYCHAIN_PASSWORD" build.keychain

      - name: Build Release
        env:
          VERSION: \${{ needs.prepare.outputs.version }}
          DEVELOPER_ID_APPLICATION: \${{ secrets.DEVELOPER_ID_APPLICATION }}
          APPLE_ID: \${{ secrets.APPLE_ID }}
          APPLE_APP_SPECIFIC_PASSWORD: \${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
          APPLE_TEAM_ID: \${{ secrets.APPLE_TEAM_ID }}
        run: |
          if [[ -n "\$APPLE_ID" && -n "\$APPLE_APP_SPECIFIC_PASSWORD" && -n "\$APPLE_TEAM_ID" ]]; then
            export NOTARIZE=1
          else
            export NOTARIZE=0
          fi
          ./build_dmg.sh

      - name: Upload Release Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: release
          path: |
            ${APP_NAME}-\${{ needs.prepare.outputs.version }}.dmg
            ${APP_NAME}-\${{ needs.prepare.outputs.version }}.dmg.sha256

  release:
    name: Publish Release
    needs: [prepare, build]
    runs-on: macos-26

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download Release Artifacts
        uses: actions/download-artifact@v4
        with:
          path: dist

      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          tag_name: \${{ needs.prepare.outputs.tag }}
          files: |
            dist/release/${APP_NAME}-\${{ needs.prepare.outputs.version }}.dmg
            dist/release/${APP_NAME}-\${{ needs.prepare.outputs.version }}.dmg.sha256
          generate_release_notes: true
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
EOF
else
  cat > "$OUTPUT" <<EOF
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-latest

    permissions:
      contents: write

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Setup pnpm
        uses: pnpm/action-setup@v4
        with:
          version: 9

      - name: Get pnpm store directory
        shell: bash
        run: |
          echo "STORE_PATH=\$(pnpm store path --silent)" >> \$GITHUB_ENV

      - name: Setup pnpm cache
        uses: actions/cache@v4
        with:
          path: \${{ env.STORE_PATH }}
          key: \${{ runner.os }}-pnpm-store-\${{ hashFiles('**/pnpm-lock.yaml') }}
          restore-keys: |
            \${{ runner.os }}-pnpm-store-

      - name: Get version from tag
        id: get_version
        run: echo "VERSION=\${GITHUB_REF#refs/tags/v}" >> \$GITHUB_OUTPUT

      - name: Update package.json version
        run: npm version \${{ steps.get_version.outputs.VERSION }} --no-git-tag-version

      - name: Install dependencies
        run: pnpm install

      - name: Build and package
        run: pnpm build:mac
        env:
          GH_TOKEN: \${{ secrets.GITHUB_TOKEN }}
          CSC_LINK: \${{ secrets.CSC_LINK }}
          CSC_KEY_PASSWORD: \${{ secrets.CSC_KEY_PASSWORD }}
          APPLE_ID: \${{ secrets.APPLE_ID }}
          APPLE_APP_SPECIFIC_PASSWORD: \${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
          APPLE_TEAM_ID: \${{ secrets.APPLE_TEAM_ID }}

      - name: Create Release
        uses: softprops/action-gh-release@v2
        with:
          name: ${APP_NAME} v\${{ steps.get_version.outputs.VERSION }}
          draft: false
          prerelease: false
          generate_release_notes: true
          files: |
            dist/*.dmg
            dist/*.zip
            dist/*.blockmap
            dist/latest-mac.yml
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
EOF
fi

echo "Created $OUTPUT" >&2
printf '{"output":"%s","type":"%s","app_name":"%s"}\n' "$OUTPUT" "$TYPE" "$APP_NAME"
