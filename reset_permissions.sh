#!/bin/bash

echo "🔧 Resetting Accessibility Permissions for Hotkeys & Shortcuts"
echo ""
echo "This will remove any old permissions and let you grant fresh ones."
echo ""

# Find all instances of the app
echo "Looking for app instances..."
XCODE_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "HotkeysAndShortcuts.app" 2>/dev/null | head -1)
DESKTOP_APP="/Users/$USER/Desktop/HotkeysAndShortcuts/HotkeysAndShortcuts.app"

if [ -n "$XCODE_APP" ]; then
    echo "Found Xcode build: $XCODE_APP"
fi

echo ""
echo "To reset permissions, run these commands:"
echo ""
echo "1. Remove old entries (requires password):"
echo "   tccutil reset Accessibility com.kale.HotkeysAndShortcuts"
echo ""
echo "2. Then relaunch the app to grant fresh permissions"
echo ""
echo "Running reset now..."
tccutil reset Accessibility com.kale.HotkeysAndShortcuts

echo ""
echo "✅ Permissions reset. Please relaunch the app to grant fresh permissions."
