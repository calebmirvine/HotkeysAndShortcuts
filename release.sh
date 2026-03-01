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

# Path to Sparkle 2 sign_update binary
SIGN_UPDATE_BIN="/Users/kale/Library/Developer/Xcode/DerivedData/HotkeysAndShortcuts-fkapyvsuuhzfblfzqmwxmboenlnx/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"

# Path to built app
BUILT_APP="$SCRIPT_DIR/HotkeysAndShortcuts.app"
INFO_PLIST="$SCRIPT_DIR/HotkeysAndShortcuts/Info.plist"
APPCAST_FILE="$SCRIPT_DIR/appcast.xml"

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
echo -e "${BLUE}   Hotkeys & Shortcuts Release Script${NC}"
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

# Check if built app exists
if [[ ! -d "$BUILT_APP" ]]; then
    error_exit "Built app not found at: $BUILT_APP\nPlease build and export the app first (Product > Archive > Export)"
fi

# Check if sign_update binary exists
if [[ ! -x "$SIGN_UPDATE_BIN" ]]; then
    error_exit "sign_update binary not found or not executable at: $SIGN_UPDATE_BIN"
fi

# Extract version and build number from Info.plist
info_msg "Reading version information from Info.plist..."
VERSION=$(defaults read "$INFO_PLIST" CFBundleShortVersionString 2>/dev/null || error_exit "Failed to read CFBundleShortVersionString from Info.plist")
BUILD=$(defaults read "$INFO_PLIST" CFBundleVersion 2>/dev/null || error_exit "Failed to read CFBundleVersion from Info.plist")

echo ""
echo -e "${GREEN}Version: $VERSION${NC}"
echo -e "${GREEN}Build:   $BUILD${NC}"
echo ""

# Ask for release notes
echo -e "${YELLOW}Enter release notes (one per line, press Ctrl+D when done):${NC}"
RELEASE_NOTES=$(cat)

if [[ -z "$RELEASE_NOTES" ]]; then
    warn_msg "No release notes provided"
    RELEASE_NOTES="Release version $VERSION"
fi

# Create zip filename
ZIP_FILE="$SCRIPT_DIR/HotkeysAndShortcuts-$VERSION.zip"

# Check if zip already exists
if [[ -f "$ZIP_FILE" ]]; then
    warn_msg "Zip file already exists: $ZIP_FILE"
    read -p "Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error_exit "Aborted by user"
    fi
    rm "$ZIP_FILE"
fi

# Create the zip file
info_msg "Creating zip file: $ZIP_FILE"
cd "$SCRIPT_DIR"
ditto -c -k --keepParent "$BUILT_APP" "$ZIP_FILE" || error_exit "Failed to create zip file"
success_msg "Zip file created successfully"

# Get file size
FILE_SIZE=$(stat -f%z "$ZIP_FILE")
success_msg "File size: $FILE_SIZE bytes"

# Generate EdDSA signature
info_msg "Generating EdDSA signature..."
SIGNATURE=$(echo "$SPARKLE_PRIVATE_KEY" | "$SIGN_UPDATE_BIN" "$ZIP_FILE" 2>&1) || error_exit "Failed to generate signature"
success_msg "Signature generated"

# Get current date in RFC 822 format
PUB_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S %z")

# Create release notes HTML
info_msg "Formatting release notes..."
NOTES_HTML="<ul>"
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        # Escape XML special characters
        line=$(echo "$line" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
        NOTES_HTML="${NOTES_HTML}\n\t\t\t\t<li>${line}</li>"
    fi
done <<< "$RELEASE_NOTES"
NOTES_HTML="${NOTES_HTML}\n\t\t\t</ul>"

# Create temporary file with new item
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

# Backup appcast.xml
info_msg "Updating appcast.xml..."
cp "$APPCAST_FILE" "$APPCAST_FILE.backup"

# Insert new item after <channel> tag using sed
sed -e '/<channel>/r '"$TEMP_ITEM" "$APPCAST_FILE.backup" > "$APPCAST_FILE"

# Clean up temp file
rm "$TEMP_ITEM"

success_msg "appcast.xml updated"

# Show summary
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

# Commit and push changes
echo -e "${YELLOW}Do you want to commit and push changes to git? (y/n)${NC}"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    info_msg "Committing changes..."
    git add appcast.xml
    git commit -m "Release v$VERSION" || warn_msg "Nothing to commit (changes may already be committed)"

    info_msg "Pushing to GitHub..."
    git push origin main || error_exit "Failed to push to GitHub"
    success_msg "Pushed to GitHub"
fi

# Create GitHub release
echo ""
echo -e "${YELLOW}Do you want to create a GitHub release? (y/n)${NC}"
read -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Check if gh CLI is installed
    if command -v gh &> /dev/null; then
        info_msg "Creating GitHub release using gh CLI..."
        gh release create "v$VERSION" \
            "$ZIP_FILE" \
            --title "v$VERSION" \
            --notes "$RELEASE_NOTES" \
            || warn_msg "Failed to create GitHub release (may already exist)"
        success_msg "GitHub release created"
    else
        warn_msg "GitHub CLI (gh) not installed"
        echo ""
        echo -e "${YELLOW}Please create the release manually:${NC}"
        echo "1. Go to: https://github.com/calebmirvine/HotkeysAndShortcuts/releases/new"
        echo "2. Tag: v$VERSION"
        echo "3. Title: v$VERSION"
        echo "4. Upload: $ZIP_FILE"
        echo "5. Release notes:"
        echo "$RELEASE_NOTES"
        echo ""
        echo -e "${YELLOW}Press Enter when done...${NC}"
        read
    fi
fi

# Final message
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}         Release Complete! 🎉${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Next steps:"
echo "1. Verify the release on GitHub:"
echo "   https://github.com/calebmirvine/HotkeysAndShortcuts/releases"
echo "2. Users will be notified of the update automatically"
echo ""

# Clean up backup
rm "$APPCAST_FILE.backup"
