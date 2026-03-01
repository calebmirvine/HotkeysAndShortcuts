# Hotkeys & Shortcuts

A native macOS menu bar app that intercepts keyboard events at the system level to execute Apple Shortcuts and manage windows. Built entirely in Swift and SwiftUI.

## Overview

Custom keyboard shortcuts that override system-level events to trigger Apple Shortcuts or perform window management actions (snap, resize, move between displays).

## Technical Skills Demonstrated

**Core Technologies**
- Swift 5.9+ with async/await concurrency
- SwiftUI with AppKit integration (NSStatusBar, NSWorkspace)
- Core Graphics (CGEvent API)
- Accessibility APIs (AXUIElement)

**System-Level Programming**
- **CGEvent Tapping**: High-priority event interception using `.headInsertEventTap` to capture keyboard events before applications
- **Process Management**: CLI integration with `/usr/bin/shortcuts` for executing Apple Shortcuts
- **Multi-Display Geometry**: Calculating window positions across displays with different coordinate systems
- **Launch Agent Management**: ServiceManagement API for launch-at-login functionality (macOS 13+)

**Architecture & Patterns**
- MVVM pattern with @Observable macro
- Singleton managers for centralized state
- Codable persistence with UserDefaults
- Event-driven design for keyboard interception

**Distribution & Updates**
- Code signing for macOS Gatekeeper
- Automatic updates via Sparkle framework with EdDSA cryptographic signing
- GitHub releases integration

## Key Challenges

**Event Tap Permissions**: Implementing Accessibility API authorization with graceful permission denial handling and automatic recovery when permissions are granted.

**Event Priority Management**: Ensuring custom hotkeys execute before system shortcuts by using `.headInsertEventTap` placement in the event stream.

**Multi-Display Coordination**: Calculating correct window positions across displays with different resolutions and coordinate systems.

**SwiftUI/AppKit Bridge**: Integrating SwiftUI's declarative lifecycle with AppKit's imperative NSStatusBar API for menu bar functionality.

## Requirements

- macOS 13.0+ (Ventura)
- Xcode 15+
- Accessibility permissions for keyboard event interception

## Setup

1. Grant Accessibility permissions: System Settings > Privacy & Security > Accessibility
2. Launch app and configure custom keyboard shortcuts
3. Shortcuts will intercept at system level, overriding application shortcuts


