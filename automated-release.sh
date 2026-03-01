#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_FILE="$SCRIPT_DIR/.env"

# Error handling function
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Success message function
success_msg() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Info message function
info_msg() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Warning message function
warn_msg() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Print header
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Automated Hotkeys & Shortcuts Release${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if .env file exists
if [[ ! -f "$ENV_FILE" ]]; then
    error_exit ".env file not found at: $ENV_FILE"
fi

# Load environment variables from .env file
info_msg "Loading environment variables from .env..."
set -a
source "$ENV_FILE"
set +a

# Check if private key environment variable is set
if [[ -z "$SPARKLE_PRIVATE_KEY" ]]; then
    error_exit "SPARKLE_PRIVATE_KEY environment variable is not set in .env file"
fi

# Check for required parameters
if [[ $# -lt 2 ]]; then
    echo -e "${YELLOW}Usage: $0 <version> <build> [release_notes_file]${NC}"
    echo ""
    echo "Examples:"
    echo "  $0 0.1.4 5 notes.txt"
    echo "  $0 0.1.4 5"
    echo ""
    echo "If release_notes_file is not provided, you'll be prompted to enter notes."
    exit 1
fi

VERSION="$1"
BUILD="$2"
NOTES_FILE="$3"

echo -e "${GREEN}Version: $VERSION${NC}"
echo -e "${GREEN}Build:   $BUILD${NC}"
echo ""

# Get release notes
if [[ -n "$NOTES_FILE" && -f "$NOTES_FILE" ]]; then
    info_msg "Reading release notes from: $NOTES_FILE"
    RELEASE_NOTES=$(cat "$NOTES_FILE")
else
    echo -e "${YELLOW}Enter release notes (one per line, press Ctrl+D when done):${NC}"
    RELEASE_NOTES=$(cat)
fi

if [[ -z "$RELEASE_NOTES" ]]; then
    warn_msg "No release notes provided"
    RELEASE_NOTES="Release version $VERSION"
fi

# Step 1: Update version in Xcode project
info_msg "Updating version in Xcode project..."
cd "$SCRIPT_DIR"

xcrun agvtool new-marketing-version "$VERSION" > /dev/null 2>&1 || error_exit "Failed to set marketing version"
xcrun agvtool new-version -all "$BUILD" > /dev/null 2>&1 || error_exit "Failed to set build version"

success_msg "Version updated to $VERSION (build $BUILD)"

# Step 2: Clean and build
info_msg "Building app (this may take a minute)..."

xcodebuild clean build \
  -scheme HotkeysAndShortcuts \
  -configuration Release \
  -derivedDataPath ./build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  > /tmp/xcodebuild.log 2>&1

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Build failed. See /tmp/xcodebuild.log for details${NC}"
    tail -20 /tmp/xcodebuild.log
    exit 1
fi

success_msg "Build completed successfully"

# Step 3: Copy built app to root
info_msg "Copying built app to project root..."
rm -rf "$SCRIPT_DIR/HotkeysAndShortcuts.app"
ditto "$SCRIPT_DIR/build/Build/Products/Release/HotkeysAndShortcuts.app" "$SCRIPT_DIR/HotkeysAndShortcuts.app"

# Verify version in built app
BUILT_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$SCRIPT_DIR/HotkeysAndShortcuts.app/Contents/Info.plist")
BUILT_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$SCRIPT_DIR/HotkeysAndShortcuts.app/Contents/Info.plist")

if [[ "$BUILT_VERSION" != "$VERSION" || "$BUILT_BUILD" != "$BUILD" ]]; then
    error_exit "Built app has wrong version! Expected: $VERSION ($BUILD), Got: $BUILT_VERSION ($BUILT_BUILD)"
fi

success_msg "Built app verified: $BUILT_VERSION (build $BUILT_BUILD)"

# Step 4: Create zip file
ZIP_FILE="$SCRIPT_DIR/HotkeysAndShortcuts-$VERSION.zip"

if [[ -f "$ZIP_FILE" ]]; then
    warn_msg "Zip file already exists: $ZIP_FILE"
    rm "$ZIP_FILE"
fi

info_msg "Creating zip file..."
ditto -c -k --keepParent "$SCRIPT_DIR/HotkeysAndShortcuts.app" "$ZIP_FILE" || error_exit "Failed to create zip file"

FILE_SIZE=$(stat -f%z "$ZIP_FILE")
success_msg "Zip file created: $FILE_SIZE bytes"

# Step 5: Generate signature
info_msg "Generating EdDSA signature..."
SIGN_UPDATE_BIN="/Users/kale/Library/Developer/Xcode/DerivedData/HotkeysAndShortcuts-fkapyvsuuhzfblfzqmwxmboenlnx/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"

if [[ ! -x "$SIGN_UPDATE_BIN" ]]; then
    error_exit "sign_update binary not found at: $SIGN_UPDATE_BIN"
fi

SIGNATURE_OUTPUT=$(echo "$SPARKLE_PRIVATE_KEY" | "$SIGN_UPDATE_BIN" "$ZIP_FILE" 2>&1)
SIGNATURE=$(echo "$SIGNATURE_OUTPUT" | grep -o 'sparkle:edSignature="[^"]*"' | sed 's/sparkle:edSignature="//;s/"//')

if [[ -z "$SIGNATURE" ]]; then
    error_exit "Failed to generate signature"
fi

success_msg "Signature generated"

# Step 6: Update appcast.xml
info_msg "Updating appcast.xml..."

PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S %z")

# Format release notes as HTML list
NOTES_HTML="<ul>"
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        # Escape XML special characters
        line=$(echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
        NOTES_HTML="${NOTES_HTML}\n\t\t\t\t\t\t<li>${line}</li>"
    fi
done <<< "$RELEASE_NOTES"
NOTES_HTML="${NOTES_HTML}\n\t\t\t\t\t</ul>"

# Create new item
TEMP_ITEM=$(mktemp)
cat > "$TEMP_ITEM" << XMLEOF
		<item>
			<title>Version $VERSION</title>
			<description>
				<![CDATA[
					<h2>Version $VERSION</h2>
$(echo -e "$NOTES_HTML")
				]]>
			</description>
			<pubDate>$PUB_DATE</pubDate>
			<enclosure
			url="https://github.com/calebmirvine/HotkeysAndShortcuts/releases/download/v$VERSION/HotkeysAndShortcuts-$VERSION.zip"
			sparkle:version="$BUILD"
			sparkle:shortVersionString="$VERSION"
			sparkle:edSignature="$SIGNATURE"
			length="$FILE_SIZE"
			type="application/octet-stream"
			/>
			<sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
		</item>
XMLEOF

# Backup appcast
cp "$SCRIPT_DIR/appcast.xml" "$SCRIPT_DIR/appcast.xml.backup"

# Insert new item after <channel> tag
sed -e '/<channel>/r '"$TEMP_ITEM" "$SCRIPT_DIR/appcast.xml.backup" > "$SCRIPT_DIR/appcast.xml.tmp"
mv "$SCRIPT_DIR/appcast.xml.tmp" "$SCRIPT_DIR/appcast.xml"

# Validate XML
xmllint --noout "$SCRIPT_DIR/appcast.xml" || error_exit "Generated invalid XML"

rm "$TEMP_ITEM"
success_msg "appcast.xml updated and validated"

# Step 7: Show summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}           Release Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Version:    ${GREEN}$VERSION${NC}"
echo -e "Build:      ${GREEN}$BUILD${NC}"
echo -e "Zip file:   ${GREEN}$ZIP_FILE${NC}"
echo -e "File size:  ${GREEN}$FILE_SIZE bytes${NC}"
echo -e "Signature:  ${GREEN}${SIGNATURE:0:40}...${NC}"
echo ""

# Step 8: Commit and push
echo -e "${YELLOW}Do you want to commit and push changes to git? (y/n)${NC}"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    info_msg "Committing changes..."
    git add appcast.xml HotkeysAndShortcuts.xcodeproj/project.pbxproj
    git commit -m "Release v$VERSION" || warn_msg "Nothing to commit"

    info_msg "Pushing to GitHub..."
    git push origin main || error_exit "Failed to push to GitHub"
    success_msg "Pushed to GitHub"
fi

# Step 9: Create GitHub release
echo ""
echo -e "${YELLOW}Do you want to create a GitHub release? (y/n)${NC}"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v /opt/homebrew/bin/gh &> /dev/null; then
        info_msg "Creating GitHub release..."
        /opt/homebrew/bin/gh release create "v$VERSION" \
            "$ZIP_FILE" \
            --title "v$VERSION" \
            --notes "$RELEASE_NOTES" \
            || warn_msg "Failed to create GitHub release (may already exist)"
        success_msg "GitHub release created"
    else
        warn_msg "GitHub CLI (gh) not installed"
        echo ""
        echo -e "${YELLOW}Install with: brew install gh${NC}"
    fi
fi

# Step 10: Clean up
rm -f "$SCRIPT_DIR/appcast.xml.backup"

# Final message
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}         Release Complete! 🎉${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Release URL: https://github.com/calebmirvine/HotkeysAndShortcuts/releases/tag/v$VERSION"
echo ""
echo "Users will be notified of the update automatically via Sparkle!"
echo ""
