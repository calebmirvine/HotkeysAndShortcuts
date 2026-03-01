# Testing Sparkle Auto-Updates

## Prerequisites

1. **Sparkle CLI tools installed:**
   ```bash
   brew install sparkle
   ```

2. **Your keys are already set up** (in `.env` file):
   - Public key: `1k4KpxuEudNcxjntceEwn0YIKJ7TULoKrDJoN8ibZVQ=`
   - Private key: `DSUawCG34b1qRW0I/dk9fMjgn2HLUrR1TrqbkhCoisU=`

## Method 1: Test with Lower Version Number

The easiest way to test is to **temporarily lower your app's version**, then create a release with a higher version.

### Steps:

1. **Note your current version** in `Info.plist`:
   ```bash
   /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" HotkeysAndShortcuts/Info.plist
   ```

2. **Lower the version temporarily** (e.g., if current is 1.0.0, set to 0.9.0):
   ```bash
   /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 0.9.0" HotkeysAndShortcuts/Info.plist
   ```

3. **Build the app** with the lower version:
   ```bash
   xcodebuild -scheme HotkeysAndShortcuts -configuration Release clean build
   ```

4. **Run the app** - this is now version 0.9.0

5. **Create a test release** with version 1.0.0:
   - Build: `xcodebuild -scheme HotkeysAndShortcuts -configuration Release clean archive -archivePath build/HotkeysAndShortcuts.xcarchive`
   - Export: Open Xcode Organizer → Archives → Export → select the archive
   - Compress: `ditto -c -k --sequesterRsrc --keepParent HotkeysAndShortcuts.app HotkeysAndShortcuts-1.0.0.zip`
   - Sign: `sign_update HotkeysAndShortcuts-1.0.0.zip` (use your private key from .env)
   - Get file size: `ls -l HotkeysAndShortcuts-1.0.0.zip | awk '{print $5}'`

6. **Create GitHub release:**
   ```bash
   gh release create v1.0.0 HotkeysAndShortcuts-1.0.0.zip --title "Version 1.0.0" --notes "Test release"
   ```

7. **Update appcast.xml** with the release info:
   ```xml
   <item>
       <title>Version 1.0.0</title>
       <description><![CDATA[<h2>Test Release</h2>]]></description>
       <pubDate>Fri, 28 Feb 2026 12:00:00 +0000</pubDate>
       <enclosure
           url="https://github.com/calebmirvine/HotkeysAndShortcuts/releases/download/v1.0.0/HotkeysAndShortcuts-1.0.0.zip"
           sparkle:version="1.0.0"
           sparkle:shortVersionString="1.0.0"
           sparkle:edSignature="SIGNATURE_FROM_SIGN_UPDATE"
           length="FILE_SIZE_IN_BYTES"
           type="application/octet-stream"
       />
       <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
   </item>
   ```

8. **Push appcast.xml to GitHub:**
   ```bash
   git add appcast.xml
   git commit -m "Add test release to appcast"
   git push
   ```

9. **Test the update**:
   - Open the app (version 0.9.0)
   - Go to Settings → Updates
   - Click "Check for Updates Now"
   - You should see an update prompt for version 1.0.0!

## Method 2: Test Update Check UI (No Actual Update)

You can test the update checking mechanism without creating a release:

1. **Check Console logs** when clicking "Check for Updates Now"
2. **Verify the feed URL is accessible:**
   ```bash
   curl https://raw.githubusercontent.com/calebmirvine/HotkeysAndShortcuts/main/appcast.xml
   ```

3. **Check for errors** in Console.app (filter by "Sparkle")

## Method 3: Use Sparkle's Test App

If you want to test without modifying your app:

1. Clone Sparkle source:
   ```bash
   git clone https://github.com/sparkle-project/Sparkle.git
   cd Sparkle
   ```

2. Build the test app and experiment with their examples

## Debugging Tips

**Enable verbose Sparkle logging** by adding to your `Info.plist`:
```xml
<key>SUEnableSystemProfiling</key>
<true/>
```

**Check Console.app** for Sparkle messages while testing:
- Open Console.app
- Filter by "Sparkle" or your app name
- Look for update check attempts and errors

**Common Issues:**

1. **"No updates found"** - appcast.xml version ≤ current app version
2. **Signature verification failed** - Wrong private key used, or signature not copied correctly
3. **Cannot reach feed** - appcast.xml not pushed to GitHub, or wrong URL in Info.plist
4. **Download fails** - ZIP file not uploaded to GitHub release

## Quick Test Script

Save this as `test_sparkle.sh`:

```bash
#!/bin/bash

# Current version
CURRENT_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" HotkeysAndShortcuts/Info.plist)
echo "Current version: $CURRENT_VERSION"

# Temporarily set to 0.9.0
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 0.9.0" HotkeysAndShortcuts/Info.plist
echo "Version set to 0.9.0 for testing"

# Build
xcodebuild -scheme HotkeysAndShortcuts -configuration Release clean build

echo "App built with version 0.9.0"
echo "Run the app, then check for updates in Settings → Updates"
echo "After testing, restore version with: /usr/libexec/PlistBuddy -c \"Set :CFBundleShortVersionString $CURRENT_VERSION\" HotkeysAndShortcuts/Info.plist"
```

Run it: `chmod +x test_sparkle.sh && ./test_sparkle.sh`

---

**Sources:**
- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Testing Updates](https://sparkle-project.org/documentation/testing/)
