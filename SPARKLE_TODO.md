# Sparkle Setup Checklist

Complete these steps to finish setting up automatic updates:

## ✅ Already Done
- [x] Sparkle framework added to project
- [x] UpdateManager controller created
- [x] Update settings UI added to Settings window
- [x] Info.plist configured with Sparkle keys
- [x] AppDelegate initializes UpdateManager
- [x] appcast.xml template created
- [x] Comprehensive setup documentation written

## 🔲 Next Steps (Required)

### 1. Generate EdDSA Keys
```bash
# Install Sparkle tools
brew install sparkle

# Generate your signing keys
generate_keys
```

Save the output:
- **Public key** → Update in `HotkeysAndShortcuts/Info.plist` under `SUPublicEDKey`
- **Private key** → Store securely (never commit to git!)

### 2. Update Info.plist
Open `HotkeysAndShortcuts/Info.plist` and replace:
- `YOUR_USERNAME/YOUR_REPO` in `SUFeedURL`
- `YOUR_PUBLIC_KEY_WILL_GO_HERE` in `SUPublicEDKey`

### 3. Set Up GitHub Repository
- Create a GitHub repository for your app (if not already done)
- Add `appcast.xml` to the repository root
- Push to GitHub

### 4. Test the Implementation
1. Build and run the app
2. Open Settings → Updates tab
3. Verify the UI appears correctly
4. Note: Updates won't work until you create your first release

### 5. Create Your First Release (When Ready)
Follow the detailed steps in `SPARKLE_SETUP.md`:
1. Build and archive your app
2. Create a signed ZIP
3. Sign with Sparkle's `sign_update` tool
4. Create GitHub release
5. Update `appcast.xml` with release info
6. Push `appcast.xml` to GitHub

## 📋 Quick Commands Reference

```bash
# Generate keys
generate_keys

# Build release
xcodebuild -scheme HotkeysAndShortcuts -configuration Release clean archive

# Create ZIP
ditto -c -k --sequesterRsrc --keepParent HotkeysAndShortcuts.app HotkeysAndShortcuts.zip

# Sign update
sign_update HotkeysAndShortcuts.zip /path/to/private_key.pem

# Create GitHub release
gh release create v1.0.0 HotkeysAndShortcuts.zip
```

## 📚 Documentation
- Full setup guide: `SPARKLE_SETUP.md`
- Sparkle docs: https://sparkle-project.org/documentation/

## ⚠️ Important Notes
- Keep your private key SECRET - never commit to version control
- Add `*.pem` and `.sparkle_keys/` to `.gitignore`
- Test updates with a lower version number first
- Appcast URL must be publicly accessible
