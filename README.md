# Hotkeys & Shortcuts

**A native macOS menu bar app that intercepts keyboard events at the system level to run Apple Shortcuts and manage windows—built entirely in Swift & SwiftUI.**

## What It Does

- Registers **custom keyboard shortcuts** that override app and system shortcuts
- Executes **Apple Shortcuts** via CLI integration (`/usr/bin/shortcuts`)
- Provides **window management** (snap, resize, move between displays)
- Uses **CGEvent tapping** for system-level event interception

## Tech Stack

**Languages & Frameworks:**
- Swift 5.9+ with modern concurrency (async/await)
- SwiftUI for UI with AppKit integration
- Foundation, Core Graphics, Accessibility APIs

**Key Technical Features:**
- CGEvent tapping for system-level keyboard interception
- ServiceManagement for launch-at-login (macOS 13+)
- AXUIElement for window manipulation across apps
- Menu bar app architecture (NSStatusBar)
- Process execution for CLI integration

**Architecture:**
- MVVM pattern with observable objects
- Singleton managers for shared state
- Codable persistence with UserDefaults
- Event-driven design with Combine

**Distribution:**
- Packaged as DMG using [create-dmg](https://github.com/create-dmg/create-dmg)
- Code-signed for macOS Gatekeeper compatibility

---

## Implementation Highlights

**EventMonitor** - System-level keyboard capture
```swift
// CGEvent tap intercepts keys before apps see them
let eventMask = (1 << CGEventType.keyDown.rawValue)
let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,
    place: .headInsertEventTap,
    options: .defaultTap,
    eventsOfInterest: CGEventMask(eventMask),
    callback: eventCallback,
    userInfo: nil
)
```

**WindowManager** - Cross-app window manipulation
```swift
// Uses Accessibility API to control any app's windows
let frontmostApp = NSWorkspace.shared.frontmostApplication
let axApp = AXUIElementCreateApplication(frontmostApp.processIdentifier)
var windowRef: AnyObject?
AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute, &windowRef)
```

**ShortcutManager** - CLI integration for Shortcuts
```swift
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
process.arguments = ["run", shortcutName]
try process.run()
```

---

## Key Challenges Solved

1. **Event Tap Permissions**: Navigating Accessibility API authorization and handling permission denials gracefully
2. **Event Priority**: Ensuring hotkeys fire before system shortcuts using `.headInsertEventTap`
3. **Multi-Display Geometry**: Calculating window positions across displays with different resolutions
4. **SwiftUI + AppKit Hybrid**: Bridging SwiftUI lifecycle with AppKit's NSStatusBar for menu bar integration
5. **Launch Agent Management**: Using modern ServiceManagement API (avoiding deprecated SMLoginItemSetEnabled)

---

## Requirements

- macOS 13.0+ (Ventura)
- Xcode 15+
- No third-party dependencies

---

## Troubleshooting
### Keyboard Shortcuts Not Working

**Symptoms:** You've created shortcuts but pressing the key combinations doesn't trigger any actions.

**Solution:**
1. The app **requires Accessibility permissions** to intercept keyboard events
2. When you first launch the app, you should see a system popup asking for accessibility access
3. If you dismissed the popup, manually grant permissions:
   - Open **System Settings** → **Privacy & Security** → **Accessibility**
   - Find **Hotkeys & Shortcuts** in the list
   - Toggle it **ON**
4. **Restart the app** after granting permissions (the app will automatically detect the permission change and restart event monitoring)

**How the fix works:**
- The app now checks `AXIsProcessTrusted()` before creating the event tap
- When permissions are granted, it automatically restarts the event monitoring system
- A visual warning banner appears in the UI when permissions are missing
- Debug logging helps track permission status

### Shortcuts Still Not Working After Permission Grant

**Possible causes:**
1. **Key combination conflicts**: Your shortcut might conflict with a system or app shortcut
2. **Event tap not restarted**: Try quitting and relaunching the app
3. **Window management requires focused window**: Some window actions only work when an app window is focused

---


