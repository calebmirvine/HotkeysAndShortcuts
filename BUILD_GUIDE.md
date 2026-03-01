# Build & Release Guide

## Quick Start

### Prerequisites

Install required tools:
```bash
# Install Sparkle (for signing updates)
brew install sparkle

# Install create-dmg (for DMG creation)
brew install create-dmg

# Install GitHub CLI (for creating releases)
brew install gh

# Optional: Install xcpretty (for prettier build output)
gem install xcpretty
```

### Build a Release

Simply run:
```bash
./build_release.sh
```

This script will:
1. ✓ Clean previous builds
2. ✓ Build and archive the app
3. ✓ Export the application
4. ✓ Create a ZIP for Sparkle updates
5. ✓ Sign the update with your Sparkle private key
6. ✓ Create a DMG installer
7. ✓ Generate appcast.xml entry
8. ✓ Create release notes template

### After Building

All files will be in `build/Release/`:
- `HotkeysAndShortcuts-X.X.X.zip` - For Sparkle auto-updates
- `HotkeysAndShortcuts-X.X.X.dmg` - For user downloads
- `appcast_entry.xml` - Copy this into appcast.xml
- `RELEASE_NOTES.md` - Edit and use for GitHub release

## Publishing a Release

### Step 1: Edit Release Notes

Edit `build/Release/RELEASE_NOTES.md` with your changes.

### Step 2: Create GitHub Release

The build script outputs the exact command to run:
```bash
gh release create v1.0.0 \
  "build/Release/HotkeysAndShortcuts-1.0.0.dmg" \
  "build/Release/HotkeysAndShortcuts-1.0.0.zip" \
  --title "Version 1.0.0" \
  --notes-file "build/Release/RELEASE_NOTES.md"
```

### Step 3: Update appcast.xml

1. Open `appcast.xml`
2. Copy the contents of `build/Release/appcast_entry.xml`
3. Paste it into the `<channel>` section (after the comment, before `</channel>`)
4. Commit and push:
   ```bash
   git add appcast.xml
   git commit -m "Release v1.0.0"
   git push
   ```

### Step 4: Test the Update

Users with older versions will now see the update automatically!

To test yourself:
1. Lower your app version temporarily
2. Build and run
3. Click "Check for Updates Now" in Settings → Updates
4. You should see the update prompt!

## Environment Variables (.env)

The build script uses these variables from `.env`:

### Required:
- `SPARKLE_PRIVATE_KEY` - Your Sparkle private key (for signing)
- `GITHUB_REPO` - Your GitHub repository (user/repo)

### Optional:
- `CODE_SIGN_IDENTITY` - Code signing identity (default: "-" for ad-hoc)
- `DEVELOPMENT_TEAM` - Your Apple Developer Team ID
- `APPLE_ID` - For notarization (App Store distribution)

## Versioning

Update version in `HotkeysAndShortcuts/Info.plist`:
```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.0.1" HotkeysAndShortcuts/Info.plist
```

Or edit in Xcode:
1. Select project in Navigator
2. Select target → General tab
3. Update "Version" field

## Troubleshooting

### "sign_update: command not found"
```bash
brew install sparkle
```

### "create-dmg: command not found"
```bash
brew install create-dmg
```

### Build fails with signing errors
Set `CODE_SIGN_IDENTITY="-"` in `.env` for ad-hoc signing.

### DMG has wrong icon
Ensure `Assets.xcassets/AppIcon.appiconset/icon_512x512.png` exists.

### Signature verification fails
- Make sure you're using the correct private key from `.env`
- Verify the public key in `Info.plist` matches your private key

## Manual Build (Without Script)

If you prefer to build manually:

```bash
# 1. Archive
xcodebuild clean archive \
  -scheme HotkeysAndShortcuts \
  -configuration Release \
  -archivePath build/HotkeysAndShortcuts.xcarchive

# 2. Export app
cp -R build/HotkeysAndShortcuts.xcarchive/Products/Applications/HotkeysAndShortcuts.app \
  build/HotkeysAndShortcuts.app

# 3. Create ZIP
cd build
ditto -c -k --sequesterRsrc --keepParent HotkeysAndShortcuts.app HotkeysAndShortcuts.zip

# 4. Sign
sign_update HotkeysAndShortcuts.zip

# 5. Create DMG
create-dmg \
  --volname "Hotkeys & Shortcuts" \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "HotkeysAndShortcuts.app" 175 190 \
  --app-drop-link 425 190 \
  HotkeysAndShortcuts.dmg \
  HotkeysAndShortcuts.app
```

## Quick Reference

### Common Tasks

**Build release:**
```bash
./build_release.sh
```

**Update version:**
```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 1.0.1" HotkeysAndShortcuts/Info.plist
```

**Create GitHub release:**
```bash
gh release create v1.0.0 build/Release/*.{dmg,zip} --notes-file build/Release/RELEASE_NOTES.md
```

**Check current version:**
```bash
/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" HotkeysAndShortcuts/Info.plist
```

**View Sparkle keys:**
```bash
grep SPARKLE .env
```

---

## Script Location

The build script is located at: `./build_release.sh`

All configuration is in: `./.env` (never commit this!)
