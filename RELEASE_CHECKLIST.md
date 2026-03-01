# Quick Release Checklist

## ✅ Setup Complete
- [x] Sparkle framework integrated
- [x] EdDSA keys generated and configured
- [x] Info.plist updated with GitHub repo and public key
- [x] Private key stored in .env (and macOS keychain)
- [x] .gitignore configured

## 🔑 Your Sparkle Keys
**Public Key (in Info.plist):**
```
1k4KpxuEudNcxjntceEwn0YIKJ7TULoKrDJoN8ibZVQ=
```

**Private Key Location:**
- `.env` file (never commit!)
- macOS Keychain: "Private key for signing Sparkle updates"

**Repository:**
- https://github.com/calebmirvine/HotkeysAndShortcuts
- Appcast URL: https://raw.githubusercontent.com/calebmirvine/HotkeysAndShortcuts/main/appcast.xml

## 📦 Creating a Release

### 1. Build & Archive
```bash
# In Xcode: Product → Archive
# Or via command line:
xcodebuild -scheme HotkeysAndShortcuts -configuration Release clean archive \
    -archivePath build/HotkeysAndShortcuts.xcarchive

# Export the app
xcodebuild -exportArchive \
    -archivePath build/HotkeysAndShortcuts.xcarchive \
    -exportPath build/Release \
    -exportOptionsPlist ExportOptions.plist
```

### 2. Create ZIP
```bash
cd build/Release
ditto -c -k --sequesterRsrc --keepParent \
    HotkeysAndShortcuts.app HotkeysAndShortcuts-1.0.0.zip
```

### 3. Sign the Update
```bash
# Use the helper script
./sign_update.sh build/Release/HotkeysAndShortcuts-1.0.0.zip

# This will output the signature and file size for appcast.xml
```

### 4. Create GitHub Release
```bash
# Tag the release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Create release with gh CLI
gh release create v1.0.0 \
    --title "Version 1.0.0" \
    --notes "Initial release with automatic updates" \
    build/Release/HotkeysAndShortcuts-1.0.0.zip
```

### 5. Update appcast.xml
Copy the template from appcast.xml, fill in:
- Version number
- Release date
- Release notes
- URL (from GitHub release)
- Signature (from sign_update.sh)
- File size (from sign_update.sh)

### 6. Commit & Push
```bash
git add appcast.xml
git commit -m "Update appcast for v1.0.0"
git push origin main
```

## 🧪 Testing

### Test Updates UI
1. Build and run the app
2. Open Settings → Updates
3. Click "Check for Updates Now"

### Test Update Flow
1. Lower your app version temporarily
2. Create a test release
3. Run the app and check for updates
4. Verify download and installation works

## 🛠️ Helper Scripts

**sign_update.sh** - Sign a ZIP file and get appcast values
```bash
./sign_update.sh path/to/app.zip
```

## 📚 Documentation
- Full setup guide: `SPARKLE_SETUP.md`
- Sparkle docs: https://sparkle-project.org/documentation/

## ⚠️ Security Reminders
- ✅ .env is in .gitignore
- ✅ Private key is backed up in macOS Keychain
- ⚠️ Never commit .env or .pem files
- ⚠️ Always verify GitHub releases are public
- ⚠️ Test signatures before publishing
