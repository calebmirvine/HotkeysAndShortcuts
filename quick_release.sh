#!/bin/bash

# Quick Release Script - Fast version without DMG
# Perfect for testing Sparkle updates

set -e
export PATH="/opt/homebrew/bin:/opt/homebrew/Caskroom/sparkle/2.9.0/bin:/usr/local/bin:$PATH"

# Configuration
APP_NAME="HotkeysAndShortcuts"
PROJECT_DIR="$(pwd)"
VERSION=$(grep -m1 "MARKETING_VERSION = " "${APP_NAME}.xcodeproj/project.pbxproj" | sed 's/.*= \(.*\);/\1/')

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load .env
[ -f .env ] && export $(cat .env | grep -v '^#' | xargs)

echo -e "${BLUE}Quick Release v${VERSION}${NC}\n"

# Build
echo "Building..."
xcodebuild clean build -scheme "$APP_NAME" -configuration Release > /dev/null 2>&1

# Find app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "${APP_NAME}.app" | grep "Build/Products/Release" | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: App not found"
    exit 1
fi

# Create release dir
mkdir -p build/Release

# Create ZIP
cd "$(dirname "$APP_PATH")"
ZIP_NAME="${APP_NAME}-${VERSION}.zip"
ditto -c -k --sequesterRsrc --keepParent "${APP_NAME}.app" "$PROJECT_DIR/build/Release/$ZIP_NAME"
cd "$PROJECT_DIR"

# Sign
echo "$SPARKLE_PRIVATE_KEY" | /opt/homebrew/Caskroom/sparkle/2.9.0/bin/sign_update "build/Release/$ZIP_NAME" > build/Release/signature.txt

SIG=$(cat build/Release/signature.txt | grep "sparkle:edSignature=" | sed 's/.*sparkle:edSignature="\([^"]*\)".*/\1/')
SIZE=$(stat -f%z "build/Release/$ZIP_NAME")

echo -e "\n${GREEN}✓ Release created!${NC}\n"
echo "File: build/Release/$ZIP_NAME"
echo "Size: $SIZE bytes"
echo "Signature: $SIG"
echo -e "\n${BLUE}Upload command:${NC}"
echo "gh release create v${VERSION} build/Release/${ZIP_NAME} --title \"v${VERSION}\" --notes \"Test release\""
