# Sparkle Auto-Update Setup Guide

This guide explains how to set up and manage automatic updates for Hotkeys & Shortcuts using the Sparkle framework and GitHub releases.

## Overview

Sparkle is integrated into the app to provide:
- Automatic update checking in the background
- User-initiated manual update checks
- Secure, code-signed updates
- Delta updates for faster downloads
- Update notifications and installation

## Prerequisites

1. A GitHub repository for your app
2. Xcode Command Line Tools installed
3. A valid Apple Developer ID certificate for code signing

## One-Time Setup

### 1. Generate EdDSA Keys for Signing Updates

Sparkle uses EdDSA signatures to verify update authenticity. Generate your keys:

```bash
# Navigate to your project directory
cd /path/to/HotkeysAndShortcuts

# Generate the key pair (this comes with Sparkle)
# The generate_keys tool is in the Sparkle package
./generate_keys.sh
```

This will output:
- **Public key** - Add this to Info.plist
- **Private key** - Keep this SECRET and secure (never commit to git!)

**Alternative method if generate_keys isn't available:**
```bash
# Install Sparkle tools via Homebrew
brew install sparkle

# Generate keys
generate_keys
```

### 2. Update Info.plist with Your Configuration

Open `HotkeysAndShortcuts/Info.plist` and update these keys:

```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/appcast.xml</string>

<key>SUPublicEDKey</key>
<string>YOUR_ACTUAL_PUBLIC_KEY_FROM_STEP_1</string>
```

Replace:
- `YOUR_USERNAME` with your GitHub username
- `YOUR_REPO` with your repository name
- `YOUR_ACTUAL_PUBLIC_KEY_FROM_STEP_1` with the public key generated in step 1

### 3. Store Your Private Key Securely

Save your private key to a secure location:

```bash
# Create a secure directory (don't commit this!)
mkdir -p ~/.sparkle_keys
echo "YOUR_PRIVATE_KEY" > ~/.sparkle_keys/hotkeys_shortcuts_private.pem
chmod 600 ~/.sparkle_keys/hotkeys_shortcuts_private.pem
```

Add to `.gitignore`:
```
# Sparkle private keys
*.pem
.sparkle_keys/
```

## Creating a Release

### 1. Build and Archive Your App

```bash
# Archive your app in Xcode
# Product → Archive
# Or use command line:
xcodebuild -scheme HotkeysAndShortcuts -configuration Release clean archive \
  -archivePath build/HotkeysAndShortcuts.xcarchive

# Export the app
xcodebuild -exportArchive \
  -archivePath build/HotkeysAndShortcuts.xcarchive \
  -exportPath build/Release \
  -exportOptionsPlist ExportOptions.plist
```

### 2. Create a ZIP for Distribution

```bash
# Navigate to the built app
cd build/Release

# Create a ZIP (preserving code signatures)
ditto -c -k --sequesterRsrc --keepParent HotkeysAndShortcuts.app HotkeysAndShortcuts-1.0.1.zip

# Get file size for appcast
ls -l HotkeysAndShortcuts-1.0.1.zip
```

### 3. Sign the Update

Use Sparkle's `sign_update` tool to generate the signature:

```bash
# Install sign_update if not available
# It comes with Sparkle or via Homebrew: brew install sparkle

# Sign the update
sign_update HotkeysAndShortcuts-1.0.1.zip ~/.sparkle_keys/hotkeys_shortcuts_private.pem
```

This outputs an EdDSA signature like:
```
sparkle:edSignature="MCwCFHfk7..."
```

Save this signature - you'll need it for the appcast.

### 4. Create GitHub Release

```bash
# Create a git tag
git tag -a v1.0.1 -m "Release version 1.0.1"
git push origin v1.0.1

# Create GitHub release (you can also do this via GitHub UI)
gh release create v1.0.1 \
  --title "Version 1.0.1" \
  --notes "Release notes here" \
  HotkeysAndShortcuts-1.0.1.zip
```

Or via GitHub web interface:
1. Go to your repository
2. Click "Releases" → "Create a new release"
3. Tag: `v1.0.1`
4. Title: `Version 1.0.1`
5. Upload `HotkeysAndShortcuts-1.0.1.zip` as an asset
6. Publish release

### 5. Update appcast.xml

Edit the `appcast.xml` file in your repository root:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>Hotkeys & Shortcuts</title>
        <description>Most recent updates to Hotkeys & Shortcuts</description>
        <language>en</language>

        <item>
            <title>Version 1.0.1</title>
            <description>
                <![CDATA[
                    <h2>What's New in 1.0.1</h2>
                    <ul>
                        <li>Added automatic update support via Sparkle</li>
                        <li>Fixed keyboard shortcuts not working after sleep</li>
                        <li>Improved performance for hotkey detection</li>
                    </ul>
                ]]>
            </description>
            <pubDate>Fri, 28 Feb 2026 12:00:00 +0000</pubDate>
            <enclosure
                url="https://github.com/YOUR_USERNAME/YOUR_REPO/releases/download/v1.0.1/HotkeysAndShortcuts-1.0.1.zip"
                sparkle:version="1.0.1"
                sparkle:shortVersionString="1.0.1"
                sparkle:edSignature="THE_SIGNATURE_FROM_STEP_3"
                length="FILE_SIZE_IN_BYTES_FROM_STEP_2"
                type="application/octet-stream"
            />
            <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
        </item>

    </channel>
</rss>
```

Replace:
- `YOUR_USERNAME/YOUR_REPO` with your GitHub details
- `THE_SIGNATURE_FROM_STEP_3` with the actual signature
- `FILE_SIZE_IN_BYTES_FROM_STEP_2` with the file size from `ls -l`
- Update release notes in `<description>`
- Update `<pubDate>` to current date in RFC 822 format

### 6. Commit and Push appcast.xml

```bash
git add appcast.xml
git commit -m "Update appcast for v1.0.1"
git push origin main
```

## Testing Updates

### Test in Development

1. Build and run your app
2. Open Settings → Updates
3. Click "Check for Updates Now"
4. The app should detect the new version

### Test with Lower Version Number

Temporarily change your app's version to test the update flow:
1. In Xcode, select your target
2. Go to General tab
3. Change Version to something lower (e.g., 1.0.0)
4. Build and run
5. Check for updates

### Debug Issues

Enable Sparkle debug logging:
```swift
// In UpdateManager.swift, add to init():
updaterController.updater.delegate = self
```

Check Console.app for Sparkle logs.

## Automation with GitHub Actions

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest

    steps:
    - uses: actions/checkout@v3

    - name: Build app
      run: |
        xcodebuild -scheme HotkeysAndShortcuts \
          -configuration Release clean archive \
          -archivePath build/HotkeysAndShortcuts.xcarchive

        xcodebuild -exportArchive \
          -archivePath build/HotkeysAndShortcuts.xcarchive \
          -exportPath build/Release \
          -exportOptionsPlist ExportOptions.plist

    - name: Create ZIP
      run: |
        cd build/Release
        ditto -c -k --sequesterRsrc --keepParent \
          HotkeysAndShortcuts.app HotkeysAndShortcuts.zip

    - name: Sign update
      env:
        SPARKLE_PRIVATE_KEY: ${{ secrets.SPARKLE_PRIVATE_KEY }}
      run: |
        echo "$SPARKLE_PRIVATE_KEY" > private_key.pem
        SIGNATURE=$(sign_update build/Release/HotkeysAndShortcuts.zip private_key.pem)
        echo "SIGNATURE=$SIGNATURE" >> $GITHUB_ENV
        rm private_key.pem

    - name: Create Release
      uses: softprops/action-gh-release@v1
      with:
        files: build/Release/HotkeysAndShortcuts.zip
        generate_release_notes: true
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Store your private key in GitHub Secrets:
1. Go to Settings → Secrets → Actions
2. Add `SPARKLE_PRIVATE_KEY` with your private key

## Update Settings UI

Users can manage updates in the app:
- **Settings → Updates tab**
- Check for updates manually
- Enable/disable automatic checks
- Enable/disable automatic downloads

## Troubleshooting

### Updates Not Being Detected

1. **Check appcast URL**: Verify `SUFeedURL` in Info.plist is correct and accessible
2. **Verify appcast.xml**: Visit the URL in a browser - should show valid XML
3. **Check signature**: Ensure EdDSA signature matches the ZIP file
4. **Version numbers**: Ensure new version is higher than current version

### Signature Verification Failed

- Public key in Info.plist doesn't match private key used to sign
- ZIP file was modified after signing
- Signature was copied incorrectly (missing characters)

### App Won't Update

- Code signing issues - ensure app is properly signed
- Gatekeeper blocking - user needs to allow in System Settings
- File permissions - ZIP needs to be publicly accessible

## Security Best Practices

1. **Never commit private keys** - add to .gitignore
2. **Use GitHub Secrets** for CI/CD automation
3. **Always sign updates** - prevents MITM attacks
4. **Use HTTPS** for appcast feed URL
5. **Keep Sparkle updated** - check for security patches

## Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle GitHub](https://github.com/sparkle-project/Sparkle)
- [Publishing Updates Guide](https://sparkle-project.org/documentation/publishing/)
- [EdDSA Signing](https://sparkle-project.org/documentation/security/)
