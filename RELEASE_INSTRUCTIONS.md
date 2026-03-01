# Release Instructions for Hotkeys & Shortcuts

This guide covers everything you need to know about creating releases for Hotkeys & Shortcuts.

## Quick Start

### Option 1: Xcode + Manual Script (Recommended for First-Time)
```bash
# 1. Update version in Xcode (General tab)
#    - Version: 0.1.4
#    - Build: 5

# 2. Archive in Xcode
#    Product > Archive > Distribute App > Copy App
#    Save as: HotkeysAndShortcuts.app (in project root)

# 3. Run release script
./release.sh
```

### Option 2: Fully Automated (Command Line)
```bash
# One command does everything!
./automated-release.sh 0.1.4 5

# Or with a release notes file:
./automated-release.sh 0.1.4 5 notes.txt
```

---

## Detailed Instructions

### Option 1: Xcode + Manual Script

**When to use:** First time releasing, or if you want full control over the build process.

#### Step 1: Update Version in Xcode

1. Open `HotkeysAndShortcuts.xcodeproj` in Xcode
2. Select the project in the navigator (top item)
3. Under the "General" tab, find:
   - **Version**: Update to your new version (e.g., `0.1.4`)
   - **Build**: Increment by 1 (e.g., `5`)

**What this does:** Updates `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in the project settings.

#### Step 2: Build and Archive

1. In Xcode menu: **Product > Archive**
2. Wait for archive to complete
3. In the Organizer window, click **Distribute App**
4. Choose **Copy App**
5. Save as `HotkeysAndShortcuts.app` in your **project root directory**

**Important:** Make sure you save it directly in the project root, not in a subfolder!

#### Step 3: Run Release Script

```bash
./release.sh
```

The script will:
1. Read version from the built app
2. Prompt for release notes (type them, press Ctrl+D when done)
3. Create signed zip file
4. Update `appcast.xml`
5. Commit and push to GitHub (if you choose yes)
6. Create GitHub release (if you choose yes)

---

### Option 2: Fully Automated Command Line

**When to use:** After you've done it once and want to automate everything.

#### Basic Usage

```bash
./automated-release.sh <version> <build>
```

**Example:**
```bash
./automated-release.sh 0.1.4 5
```

This will:
1. Update version in Xcode project (`agvtool`)
2. Build the app via command line
3. Create signed zip
4. Update appcast.xml
5. Prompt for git commit/push
6. Prompt for GitHub release

#### With Release Notes File

Create a text file with your release notes:
```bash
cat > notes.txt <<EOF
Fixed bug in AppleScript execution
Added keyboard shortcut for new feature
Improved performance by 20%
EOF
```

Then run:
```bash
./automated-release.sh 0.1.4 5 notes.txt
```

#### Interactive Release Notes

If you don't provide a file, the script will prompt you:
```bash
./automated-release.sh 0.1.4 5
# Enter release notes (one per line, press Ctrl+D when done):
Fixed bug in AppleScript execution
Added keyboard shortcut for new feature
^D
```

---

## Version Numbering

We use **Semantic Versioning**: `MAJOR.MINOR.PATCH`

- **MAJOR** (0): Breaking changes
- **MINOR** (1): New features, backward compatible
- **PATCH** (4): Bug fixes, backward compatible

**Build number** increments with each release (1, 2, 3, 4, 5...).

### Examples

| Version | Build | Description |
|---------|-------|-------------|
| 0.1.0   | 1     | Initial release |
| 0.1.1   | 2     | Bug fix |
| 0.1.2   | 3     | Another bug fix |
| 0.2.0   | 4     | New feature |
| 1.0.0   | 5     | Major release |

---

## How Versioning Works

Your Xcode project uses **modern versioning** where the version is stored in the project settings, not directly in Info.plist.

### Files Involved

1. **`HotkeysAndShortcuts.xcodeproj/project.pbxproj`**
   - Contains: `MARKETING_VERSION` (e.g., "0.1.4")
   - Contains: `CURRENT_PROJECT_VERSION` (e.g., "5")
   - This is the **source of truth**

2. **`HotkeysAndShortcuts/Info.plist`** (source file)
   - Contains: `$(MARKETING_VERSION)` and `$(CURRENT_PROJECT_VERSION)` variables
   - These get replaced during build

3. **`HotkeysAndShortcuts.app/Contents/Info.plist`** (built app)
   - Contains: Actual version numbers (e.g., "0.1.4" and "5")
   - This is what users see and what Sparkle uses

### Command Line Version Updates

If you want to update versions without opening Xcode:

```bash
# Update version
xcrun agvtool new-marketing-version 0.1.4

# Update build number
xcrun agvtool new-version -all 5

# Verify
xcrun agvtool what-marketing-version
xcrun agvtool what-version
```

---

## Troubleshooting

### "sign_update binary not found"

The path to `sign_update` is hardcoded in the scripts. If Xcode's DerivedData location changes:

1. Find the new path:
   ```bash
   find ~/Library/Developer/Xcode/DerivedData -name "sign_update" 2>/dev/null
   ```

2. Update the path in both scripts:
   - `release.sh` (line ~16)
   - `automated-release.sh` (line ~145)

### "Built app has wrong version"

This means the build didn't pick up your version changes:

1. Clean build folder: `Product > Clean Build Folder` in Xcode
2. Update version using `agvtool`:
   ```bash
   xcrun agvtool new-marketing-version 0.1.4
   xcrun agvtool new-version -all 5
   ```
3. Rebuild

### "The update is improperly signed"

This means the signature doesn't match the uploaded file:

1. Make sure you uploaded the correct zip file to GitHub
2. Verify the appcast.xml signature matches:
   ```bash
   # Generate signature for local file
   source .env
   echo "$SPARKLE_PRIVATE_KEY" | ./sign_update.sh HotkeysAndShortcuts-X.Y.Z.zip

   # Compare with appcast.xml
   grep "sparkle:edSignature" appcast.xml | head -1
   ```
3. If they don't match, regenerate and push updated appcast.xml

### "Failed to push to GitHub"

Usually means you need to pull first:
```bash
git pull origin main
git push origin main
```

### CDN Cache Issues

If users see old appcast.xml, GitHub's CDN is cached (5-10 minutes):

- Wait 10 minutes and try again
- Or use cache-busting: append `?timestamp` to URL in testing

---

## Release Checklist

Use this checklist for each release:

- [ ] Update version and build in Xcode (or via agvtool)
- [ ] Build and archive (or use automated script)
- [ ] Test the built app locally
- [ ] Verify AppleScript/Swift features work
- [ ] Check permissions dialogs
- [ ] Run release script
- [ ] Verify zip file created
- [ ] Check appcast.xml updated correctly
- [ ] Commit and push to GitHub
- [ ] Create GitHub release
- [ ] Wait 10 minutes for CDN cache
- [ ] Test auto-update from previous version

---

## Security Notes

### Private Key Protection

- **NEVER commit `.env` file** - It contains your private signing key
- Backup `.env` securely (password manager, encrypted backup)
- If key is compromised, you'll need to generate new keys and re-release all versions

### Public Key

- Public key is in `Info.plist` - safe to commit
- Both keys must match for Sparkle to validate updates

---

## Advanced: Manual Release Steps

If scripts fail, you can do it manually:

### 1. Build
```bash
xcodebuild clean build \
  -scheme HotkeysAndShortcuts \
  -configuration Release \
  -derivedDataPath ./build
```

### 2. Create Zip
```bash
ditto -c -k --keepParent HotkeysAndShortcuts.app HotkeysAndShortcuts-X.Y.Z.zip
```

### 3. Sign
```bash
source .env
echo "$SPARKLE_PRIVATE_KEY" | sign_update HotkeysAndShortcuts-X.Y.Z.zip
```

### 4. Update appcast.xml

Add new `<item>` after `<channel>` tag:
```xml
<item>
    <title>Version X.Y.Z</title>
    <description>
        <![CDATA[
            <h2>Version X.Y.Z</h2>
            <ul>
                <li>Feature or fix description</li>
            </ul>
        ]]>
    </description>
    <pubDate>Mon, 01 Jan 2026 12:00:00 +0000</pubDate>
    <enclosure
    url="https://github.com/calebmirvine/HotkeysAndShortcuts/releases/download/vX.Y.Z/HotkeysAndShortcuts-X.Y.Z.zip"
    sparkle:version="BUILD_NUMBER"
    sparkle:shortVersionString="X.Y.Z"
    sparkle:edSignature="PASTE_SIGNATURE_HERE"
    length="FILE_SIZE"
    type="application/octet-stream"
    />
    <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
</item>
```

### 5. Commit & Push
```bash
git add appcast.xml HotkeysAndShortcuts.xcodeproj/project.pbxproj
git commit -m "Release vX.Y.Z"
git push origin main
```

### 6. GitHub Release
```bash
gh release create vX.Y.Z HotkeysAndShortcuts-X.Y.Z.zip --title "vX.Y.Z" --notes "Release notes here"
```

---

## Files Reference

| File | Purpose |
|------|---------|
| `.env` | Contains Sparkle signing keys (NEVER commit!) |
| `release.sh` | Semi-manual release script (requires Xcode build) |
| `automated-release.sh` | Fully automated release script |
| `sign_update.sh` | Standalone signature generator |
| `appcast.xml` | Sparkle update feed (commit this) |
| `RELEASE.md` | Detailed release documentation |
| `RELEASE_INSTRUCTIONS.md` | This file - quick reference guide |

---

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Verify all files in [Files Reference](#files-reference) exist
3. Check `.env` has valid keys
4. Review recent git commits for changes to release files

---

## Quick Reference

### Automated Release
```bash
./automated-release.sh 0.1.4 5
```

### Manual Release
```bash
# Update version in Xcode
# Archive and export to HotkeysAndShortcuts.app
./release.sh
```

### Version Check
```bash
# Check project settings
xcrun agvtool what-marketing-version
xcrun agvtool what-version

# Check built app
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" HotkeysAndShortcuts.app/Contents/Info.plist
```

### Sign File
```bash
source .env
echo "$SPARKLE_PRIVATE_KEY" | ./sign_update.sh file.zip
```

---

**Happy Releasing! 🚀**
