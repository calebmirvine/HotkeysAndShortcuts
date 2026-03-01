#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENV_FILE="$SCRIPT_DIR/.env"

# Path to Sparkle 2 sign_update binary
SIGN_UPDATE_BIN="/Users/kale/Library/Developer/Xcode/DerivedData/HotkeysAndShortcuts-fkapyvsuuhzfblfzqmwxmboenlnx/SourcePackages/artifacts/sparkle/Sparkle/bin/sign_update"

# Error handling function
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Check if .env file exists
if [[ ! -f "$ENV_FILE" ]]; then
    error_exit ".env file not found at: $ENV_FILE"
fi

# Load environment variables from .env file
echo -e "${YELLOW}Loading environment variables from .env...${NC}"
set -a
source "$ENV_FILE"
set +a

# Check if private key environment variable is set
if [[ -z "$SPARKLE_PRIVATE_KEY" ]]; then
    error_exit "SPARKLE_PRIVATE_KEY environment variable is not set in .env file"
fi

# Check if zip file path was provided as argument
if [[ -z "$1" ]]; then
    error_exit "Usage: $0 <path-to-update.zip>"
fi

ZIP_FILE="$1"

# Check if zip file exists
if [[ ! -f "$ZIP_FILE" ]]; then
    error_exit "Zip file not found: $ZIP_FILE"
fi

# Check if sign_update binary exists
if [[ ! -x "$SIGN_UPDATE_BIN" ]]; then
    error_exit "sign_update binary not found or not executable at: $SIGN_UPDATE_BIN"
fi

# Generate the EdDSA signature
echo -e "${YELLOW}Generating EdDSA signature for: $ZIP_FILE${NC}"
SIGNATURE=$(echo "$SPARKLE_PRIVATE_KEY" | "$SIGN_UPDATE_BIN" "$ZIP_FILE" 2>&1)

# Check if signature generation was successful
if [[ $? -ne 0 ]]; then
    error_exit "Failed to generate signature"
fi

# Print the signature clearly
echo ""
echo -e "${GREEN}✓ Signature generated successfully!${NC}"
echo ""
echo "======================================"
echo "EdDSA Signature for appcast.xml:"
echo "======================================"
echo "$SIGNATURE"
echo "======================================"
echo ""
echo -e "${YELLOW}Copy the signature above and paste it into your appcast.xml file.${NC}"
