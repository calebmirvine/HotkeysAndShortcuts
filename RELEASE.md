# Release Process

This document describes how to create a new release of Hotkeys & Shortcuts.

## Prerequisites

1. **Sparkle signing keys** - Must be set in `.env` file (never commit this file!)
2. **Xcode** - For building and archiving the app
3. **Git** - For version control
4. **GitHub CLI (optional)** - `brew install gh` for automated release creation

## Quick Release Guide

### 1. Update Version Numbers

In Xcode, update the version and build numbers:
- Open `HotkeysAndShortcuts.xcodeproj`
- Select the project in the navigator
- Update **Version** (e.g., `0.1.2`)
- Update **Build** number (increment by 1, e.g., `3`)

### 2. Build and Archive

1. In Xcode: **Product > Archive**
2. Wait for archive to complete
3. Click **Distribute App**
4. Choose **Copy App**
5. Save as `HotkeysAndShortcuts.app` in the project root directory

### 3. Run Release Script

```bash
./release.sh
```

The script will:
1. Read version from `Info.plist`
2. Ask for release notes (enter one per line, press Ctrl+D when done)
3. Create a zip file from the app
4. Generate Sparkle EdDSA signature
5. Update `appcast.xml` with the new release
6. Optionally commit and push to git
7. Optionally create GitHub release (if `gh` CLI is installed)

### 4. Verify Release

1. Check GitHub releases: https://github.com/calebmirvine/HotkeysAndShortcuts/releases
2. Verify the zip file is uploaded
3. Check that `appcast.xml` is updated in the main branch

## Manual Release (Without Script)

If you need to create a release manually:

### 1. Create Zip File

```bash
ditto -c -k --keepParent HotkeysAndShortcuts.app HotkeysAndShortcuts-VERSION.zip
```

### 2. Generate Signature

```bash
./sign_update.sh HotkeysAndShortcuts-VERSION.zip
```

Copy the signature output.

### 3. Update appcast.xml

Add a new `<item>` entry after the `<channel>` tag:

```xml
<item>
    <title>Version X.Y.Z</title>
    <description>
        <![CDATA[
            <h2>Version X.Y.Z</h2>
            <ul>
                <li>Feature 1</li>
                <li>Feature 2</li>
            </ul>
        ]]>
    </description>
    <pubDate>Mon, 01 Jan 2026 12:00:00 +0000</pubDate>
    <enclosure
    url="https://github.com/calebmirvine/HotkeysAndShortcuts/releases/download/vX.Y.Z/HotkeysAndShortcuts-X.Y.Z.zip"
    sparkle:version="BUILD_NUMBER"
    sparkle:shortVersionString="X.Y.Z"
    sparkle:edSignature="PASTE_SIGNATURE_HERE"
    length="FILE_SIZE_IN_BYTES"
    type="application/octet-stream"
    />
    <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
</item>
```

### 4. Create GitHub Release

1. Go to: https://github.com/calebmirvine/HotkeysAndShortcuts/releases/new
2. Tag: `vX.Y.Z`
3. Title: `vX.Y.Z`
4. Upload the zip file
5. Add release notes
6. Publish release

## Troubleshooting

### "sign_update binary not found"

The path to `sign_update` is hardcoded in the scripts. If Xcode's DerivedData location changes, update these files:
- `sign_update.sh`
- `release.sh`

Look for the `SIGN_UPDATE_BIN` variable and update the path.

### "Built app not found"

Make sure you exported the app as `HotkeysAndShortcuts.app` in the project root directory (not in a subdirectory).

### Permission denied when running script

Make the script executable:

```bash
chmod +x release.sh
```

### GitHub release fails

If `gh` CLI is not installed or not authenticated:

```bash
# Install
brew install gh

# Authenticate
gh auth login
```

Or create the release manually on GitHub.

## Files Involved

- **`.env`** - Contains Sparkle private key (DO NOT COMMIT)
- **`sign_update.sh`** - Generates signature for a zip file
- **`release.sh`** - Complete automated release process
- **`appcast.xml`** - Sparkle update feed (committed to git)
- **`HotkeysAndShortcuts/Info.plist`** - Version numbers source of truth

## Security Notes

- **Never commit `.env` file** - It contains the private signing key
- The private key should be backed up securely
- Only the public key is stored in `Info.plist` (safe to commit)
- GitHub releases are public, but only signed updates will be accepted by Sparkle

## Version Numbering

We use semantic versioning:
- **Major.Minor.Patch** (e.g., `0.1.2`)
- **Build number** increments with each release (e.g., `1`, `2`, `3`)

Examples:
- `0.1.0` (Build 1) - Initial release
- `0.1.1` (Build 2) - Bug fix
- `0.2.0` (Build 3) - New feature
- `1.0.0` (Build 4) - Major release
