#!/bin/bash

# Build and Release Script for Hotkeys & Shortcuts
# Creates a signed DMG and prepares for Sparkle updates

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo -e "${RED}Error: .env file not found${NC}"
    exit 1
fi

# Configuration
APP_NAME="HotkeysAndShortcuts"
SCHEME="HotkeysAndShortcuts"
PROJECT_DIR="$(pwd)"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/${APP_NAME}.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
APP_PATH="$EXPORT_PATH/${APP_NAME}.app"
DMG_DIR="$BUILD_DIR/DMG"
RELEASE_DIR="$BUILD_DIR/Release"

# Get version from Info.plist
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${APP_NAME}/Info.plist")

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Hotkeys & Shortcuts - Release Builder    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo -e "${GREEN}Version: ${VERSION}${NC}\n"

# Function to print step headers
print_step() {
    echo -e "\n${YELLOW}▶ $1${NC}"
}

# Step 1: Clean previous builds
print_step "Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$RELEASE_DIR"

# Step 2: Build and Archive
print_step "Building and archiving ${APP_NAME}..."
xcodebuild clean archive \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGN_STYLE=Automatic \
    | xcpretty || xcodebuild clean archive \
        -scheme "$SCHEME" \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGN_STYLE=Automatic

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo -e "${RED}Error: Archive failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Archive created${NC}"

# Step 3: Export app
print_step "Exporting application..."
mkdir -p "$EXPORT_PATH"
cp -R "$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app" "$APP_PATH"

if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: App export failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App exported${NC}"

# Step 4: Create ZIP for Sparkle
print_step "Creating ZIP archive for Sparkle updates..."
cd "$EXPORT_PATH"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "$ZIP_NAME"
mv "$ZIP_NAME" "$RELEASE_DIR/"
cd "$PROJECT_DIR"

ZIP_PATH="$RELEASE_DIR/$ZIP_NAME"
ZIP_SIZE=$(stat -f%z "$ZIP_PATH")

echo -e "${GREEN}✓ ZIP created: $ZIP_NAME (${ZIP_SIZE} bytes)${NC}"

# Step 5: Sign update with Sparkle
print_step "Signing update with Sparkle..."

# Check if Sparkle tools are installed
if ! command -v sign_update &> /dev/null; then
    echo -e "${YELLOW}Warning: Sparkle tools not found. Installing...${NC}"
    brew install sparkle || {
        echo -e "${RED}Error: Failed to install Sparkle. Run: brew install sparkle${NC}"
        exit 1
    }
fi

# Create temporary private key file
TEMP_KEY=$(mktemp)
echo "$SPARKLE_PRIVATE_KEY" > "$TEMP_KEY"

# Sign the update
SIGNATURE=$(sign_update "$ZIP_PATH" -f "$TEMP_KEY" 2>/dev/null | grep "sparkle:edSignature=" | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')

# Clean up temp key
rm -f "$TEMP_KEY"

if [ -z "$SIGNATURE" ]; then
    echo -e "${RED}Error: Failed to sign update${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Update signed${NC}"
echo -e "   Signature: ${SIGNATURE}"

# Step 6: Create DMG (if create-dmg is installed)
print_step "Creating DMG installer..."

if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}Warning: create-dmg not found. Installing...${NC}"
    brew install create-dmg || {
        echo -e "${YELLOW}Skipping DMG creation. Install with: brew install create-dmg${NC}"
        DMG_PATH=""
    }
fi

if command -v create-dmg &> /dev/null; then
    DMG_NAME="${APP_NAME}-${VERSION}.dmg"
    DMG_PATH="$RELEASE_DIR/$DMG_NAME"

    create-dmg \
        --volname "${APP_NAME}" \
        --volicon "${APP_NAME}/Assets.xcassets/AppIcon.appiconset/icon_512x512.png" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "${APP_NAME}.app" 175 190 \
        --hide-extension "${APP_NAME}.app" \
        --app-drop-link 425 190 \
        "$DMG_PATH" \
        "$EXPORT_PATH" \
        2>/dev/null || {
            # Fallback if icon not found
            create-dmg \
                --volname "${APP_NAME}" \
                --window-pos 200 120 \
                --window-size 600 400 \
                --icon-size 100 \
                --icon "${APP_NAME}.app" 175 190 \
                --hide-extension "${APP_NAME}.app" \
                --app-drop-link 425 190 \
                "$DMG_PATH" \
                "$EXPORT_PATH"
        }

    if [ -f "$DMG_PATH" ]; then
        echo -e "${GREEN}✓ DMG created: $DMG_NAME${NC}"
    else
        echo -e "${YELLOW}Warning: DMG creation failed${NC}"
        DMG_PATH=""
    fi
fi

# Step 7: Generate appcast.xml entry
print_step "Generating appcast.xml entry..."

PUBDATE=$(date -u +"%a, %d %b %Y %H:%M:%S %z")

APPCAST_ENTRY=$(cat <<EOF

<item>
    <title>Version ${VERSION}</title>
    <description>
        <![CDATA[
            <h2>What's New in ${VERSION}</h2>
            <ul>
                <li>Add your release notes here</li>
            </ul>
        ]]>
    </description>
    <pubDate>${PUBDATE}</pubDate>
    <enclosure
        url="https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/${ZIP_NAME}"
        sparkle:version="${VERSION}"
        sparkle:shortVersionString="${VERSION}"
        sparkle:edSignature="${SIGNATURE}"
        length="${ZIP_SIZE}"
        type="application/octet-stream"
    />
    <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
</item>
EOF
)

echo "$APPCAST_ENTRY" > "$RELEASE_DIR/appcast_entry.xml"

echo -e "${GREEN}✓ Appcast entry generated${NC}"

# Step 8: Create release notes template
print_step "Creating release notes..."

cat > "$RELEASE_DIR/RELEASE_NOTES.md" <<EOF
# Release v${VERSION}

## What's New

-

## Bug Fixes

-

## Installation

Download and install:
EOF

if [ -n "$DMG_PATH" ]; then
    echo "- **DMG**: [${APP_NAME}-${VERSION}.dmg](https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/${DMG_NAME})" >> "$RELEASE_DIR/RELEASE_NOTES.md"
fi

cat >> "$RELEASE_DIR/RELEASE_NOTES.md" <<EOF
- **ZIP**: [${APP_NAME}-${VERSION}.zip](https://github.com/${GITHUB_REPO}/releases/download/v${VERSION}/${ZIP_NAME})

## Auto-Update

If you have a previous version installed, the app will automatically notify you of this update.
EOF

echo -e "${GREEN}✓ Release notes template created${NC}"

# Step 9: Summary
echo -e "\n${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║            Build Complete! ✓               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Release files created in: ${RELEASE_DIR}${NC}\n"

echo "Files created:"
echo "  • ${ZIP_NAME} (${ZIP_SIZE} bytes)"
[ -n "$DMG_PATH" ] && echo "  • ${DMG_NAME}"
echo "  • appcast_entry.xml"
echo "  • RELEASE_NOTES.md"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "  1. Edit release notes: ${RELEASE_DIR}/RELEASE_NOTES.md"
echo "  2. Create GitHub release:"
echo -e "     ${BLUE}gh release create v${VERSION} \\${NC}"
if [ -n "$DMG_PATH" ]; then
    echo -e "     ${BLUE}  \"${RELEASE_DIR}/${DMG_NAME}\" \\${NC}"
fi
echo -e "     ${BLUE}  \"${RELEASE_DIR}/${ZIP_NAME}\" \\${NC}"
echo -e "     ${BLUE}  --title \"Version ${VERSION}\" \\${NC}"
echo -e "     ${BLUE}  --notes-file \"${RELEASE_DIR}/RELEASE_NOTES.md\"${NC}"
echo ""
echo "  3. Update appcast.xml with entry from: ${RELEASE_DIR}/appcast_entry.xml"
echo "  4. Commit and push appcast.xml to GitHub"

echo -e "\n${GREEN}Signature for appcast.xml:${NC}"
echo "  sparkle:edSignature=\"${SIGNATURE}\""

echo -e "\n${BLUE}═══════════════════════════════════════════${NC}\n"
