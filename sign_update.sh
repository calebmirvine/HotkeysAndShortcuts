#!/bin/bash

# Sparkle Update Signing Helper Script
# Usage: ./sign_update.sh <path-to-zip>

set -e

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Error: .env file not found"
    exit 1
fi

# Check if ZIP file provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-app.zip>"
    echo "Example: $0 build/HotkeysAndShortcuts-1.0.0.zip"
    exit 1
fi

ZIP_FILE="$1"

# Check if file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: File not found: $ZIP_FILE"
    exit 1
fi

# Get file size
FILE_SIZE=$(stat -f%z "$ZIP_FILE")

# Find sign_update tool
SIGN_UPDATE=$(find ~/Library/Developer/Xcode/DerivedData -name "sign_update" -type f | head -1)

if [ -z "$SIGN_UPDATE" ]; then
    echo "Error: sign_update tool not found"
    echo "Make sure you've built the project in Xcode first"
    exit 1
fi

# Create temporary private key file
TEMP_KEY=$(mktemp)
echo "$SPARKLE_PRIVATE_KEY" > "$TEMP_KEY"

# Sign the update
echo "Signing $ZIP_FILE..."
SIGNATURE=$("$SIGN_UPDATE" "$ZIP_FILE" "$TEMP_KEY")

# Clean up
rm "$TEMP_KEY"

# Display results
echo ""
echo "✅ Update signed successfully!"
echo ""
echo "File: $(basename $ZIP_FILE)"
echo "Size: $FILE_SIZE bytes"
echo ""
echo "Add this to your appcast.xml:"
echo "----------------------------------------"
echo "sparkle:edSignature=\"$SIGNATURE\""
echo "length=\"$FILE_SIZE\""
echo "----------------------------------------"
echo ""
echo "Full enclosure tag example:"
echo "<enclosure"
echo "    url=\"https://github.com/$GITHUB_REPO/releases/download/vX.X.X/$(basename $ZIP_FILE)\""
echo "    sparkle:version=\"X.X.X\""
echo "    sparkle:shortVersionString=\"X.X.X\""
echo "    sparkle:edSignature=\"$SIGNATURE\""
echo "    length=\"$FILE_SIZE\""
echo "    type=\"application/octet-stream\""
echo "/>"
