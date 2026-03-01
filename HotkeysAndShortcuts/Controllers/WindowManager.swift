//
//  WindowManager.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import Foundation
import Cocoa
import ApplicationServices

// MARK: - Window Manager

@MainActor
class WindowManager {
    static let shared = WindowManager()
    
    private init() {}
    
    // MARK: - Window Manipulation
    
    /// Moves and resizes the frontmost window to the specified position
    func moveWindow(to position: WindowPosition, onScreen screen: NSScreen? = nil) -> Bool {
        // Handle special cases that don't involve window positioning
        if position == .minimize {
            return minimizeWindow()
        }
        
        if position == .hide {
            return hideApplication()
        }
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let app = AXUIElementCreateApplication(frontmostApp.processIdentifier) as AXUIElement? else {
            print("Failed to get frontmost application")
            return false
        }
        
        // Get the frontmost window
        guard let window = getFrontmostWindow(for: app) else {
            print("Failed to get frontmost window")
            return false
        }
        
        // Get the screen to use (current screen or specified)
        let targetScreen = screen ?? getCurrentScreen() ?? NSScreen.main!
        let screenFrame = getUsableScreenFrame(for: targetScreen)
        
        // Calculate the new frame based on position
        let newFrame = calculateFrame(for: position, in: screenFrame)
        
        // Apply the new frame to the window
        return setWindowFrame(window, to: newFrame)
    }
    
    /// Moves the frontmost window to a specific screen
    func moveWindow(toScreen screenIndex: Int) -> Bool {
        guard screenIndex < NSScreen.screens.count else {
            print("Invalid screen index")
            return false
        }
        
        let targetScreen = NSScreen.screens[screenIndex]
        return moveWindow(to: .center, onScreen: targetScreen)
    }
    
    /// Moves the frontmost window to the next screen
    func moveWindowToNextScreen() -> Bool {
        let screens = NSScreen.screens
        guard screens.count > 1 else {
            print("Only one screen available")
            return false
        }
        
        guard let currentScreen = getCurrentScreen(),
              let currentIndex = screens.firstIndex(of: currentScreen) else {
            return false
        }
        
        let nextIndex = (currentIndex + 1) % screens.count
        return moveWindow(toScreen: nextIndex)
    }
    
    /// Moves the frontmost window to the previous screen
    func moveWindowToPreviousScreen() -> Bool {
        let screens = NSScreen.screens
        guard screens.count > 1 else {
            print("Only one screen available")
            return false
        }
        
        guard let currentScreen = getCurrentScreen(),
              let currentIndex = screens.firstIndex(of: currentScreen) else {
            return false
        }
        
        let previousIndex = (currentIndex - 1 + screens.count) % screens.count
        return moveWindow(toScreen: previousIndex)
    }
    
    // MARK: - Window Actions
    
    /// Minimizes the frontmost window to the Dock
    func minimizeWindow() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let app = AXUIElementCreateApplication(frontmostApp.processIdentifier) as AXUIElement? else {
            print("Failed to get frontmost application")
            return false
        }
        
        guard let window = getFrontmostWindow(for: app) else {
            print("Failed to get frontmost window")
            return false
        }
        
        // Check if window can be minimized
        var canMinimize: AnyObject?
        let canMinimizeResult = AXUIElementCopyAttributeValue(
            window,
            kAXMinimizeButtonAttribute as CFString,
            &canMinimize
        )
        
        if canMinimizeResult == .success, canMinimize != nil {
            // Press the minimize button
            let minimizeButton = canMinimize as! AXUIElement
            let result = AXUIElementPerformAction(minimizeButton, kAXPressAction as CFString)
            return result == .success
        }
        
        // Fallback: try setting minimized attribute directly
        var minimized = true as CFBoolean
        let result = AXUIElementSetAttributeValue(
            window,
            kAXMinimizedAttribute as CFString,
            minimized
        )
        
        return result == .success
    }
    
    /// Hides the frontmost application
    func hideApplication() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("Failed to get frontmost application")
            return false
        }
        
        // Use NSWorkspace to hide the application
        frontmostApp.hide()
        return true
    }
    
    /// Toggles full screen mode for the frontmost window using native controls
    func toggleFullScreen() -> Bool {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let app = AXUIElementCreateApplication(frontmostApp.processIdentifier) as AXUIElement?,
              let window = getFrontmostWindow(for: app) else {
            print("Failed to get frontmost window")
            return false
        }
        
        // Try to use the native full screen button
        var fullScreenButton: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            window,
            kAXFullScreenButtonAttribute as CFString,
            &fullScreenButton
        )
        
        if result == .success, fullScreenButton != nil {
            let button = fullScreenButton as! AXUIElement
            let pressResult = AXUIElementPerformAction(button, kAXPressAction as CFString)
            return pressResult == .success
        }
        
        // Fallback: try to set fullscreen attribute directly (may not be supported by all apps)
        var isFullScreen: AnyObject?
        let getFullScreenResult = AXUIElementCopyAttributeValue(
            window,
            "AXFullScreen" as CFString,
            &isFullScreen
        )
        
        if getFullScreenResult == .success, let currentValue = isFullScreen as? NSNumber {
            let newValue = !currentValue.boolValue as CFBoolean
            let setResult = AXUIElementSetAttributeValue(
                window,
                "AXFullScreen" as CFString,
                newValue
            )
            return setResult == .success
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    
    private func getFrontmostWindow(for app: AXUIElement) -> AXUIElement? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value)
        
        if result == .success, value != nil {
            return (value as! AXUIElement)
        }
        
        return nil
    }
    
    private func getCurrentScreen() -> NSScreen? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let app = AXUIElementCreateApplication(frontmostApp.processIdentifier) as AXUIElement?,
              let window = getFrontmostWindow(for: app),
              let windowFrame = getWindowFrame(window) else {
            return NSScreen.main
        }
        
        // Find the screen that contains the center of the window
        let windowCenter = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
        
        for screen in NSScreen.screens {
            if screen.frame.contains(windowCenter) {
                return screen
            }
        }
        
        return NSScreen.main
    }
    
    private func getUsableScreenFrame(for screen: NSScreen) -> CGRect {
        // Use visibleFrame to account for menu bar and dock
        let visibleFrame = screen.visibleFrame
        
        // Debug: Print screen information
        #if DEBUG
        print("Screen frame: \(screen.frame)")
        print("Visible frame: \(visibleFrame)")
        print("Menu bar height: \(screen.frame.height - visibleFrame.maxY + visibleFrame.origin.y)")
        #endif
        
        return visibleFrame
    }
    
    private func calculateFrame(for position: WindowPosition, in screenFrame: CGRect) -> CGRect {
        let x = screenFrame.origin.x
        let y = screenFrame.origin.y
        let width = screenFrame.width
        let height = screenFrame.height
        
        // Note: macOS uses a coordinate system where (0,0) is at the bottom-left
        // visibleFrame already accounts for menu bar and dock
        
        switch position {
        case .leftHalf:
            return CGRect(x: x, y: y, width: width / 2, height: height)
            
        case .rightHalf:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height)
            
        case .topHalf:
            // Top half: y position stays at the bottom of the visible area + half the height
            return CGRect(x: x, y: y + height / 2, width: width, height: height / 2)
            
        case .bottomHalf:
            // Bottom half: y position is at the bottom of the visible area
            return CGRect(x: x, y: y, width: width, height: height / 2)
            
        case .fullScreen, .maximize:
            return screenFrame
            
        case .center:
            let centerWidth = width * 0.7
            let centerHeight = height * 0.7
            return CGRect(
                x: x + (width - centerWidth) / 2,
                y: y + (height - centerHeight) / 2,
                width: centerWidth,
                height: centerHeight
            )
            
        case .topLeft:
            // Top-left quarter: x at left edge, y at bottom of visible + half height
            return CGRect(x: x, y: y + height / 2, width: width / 2, height: height / 2)
            
        case .topRight:
            // Top-right quarter: x at halfway point, y at bottom of visible + half height
            return CGRect(x: x + width / 2, y: y + height / 2, width: width / 2, height: height / 2)
            
        case .bottomLeft:
            // Bottom-left quarter: x at left edge, y at bottom of visible
            return CGRect(x: x, y: y, width: width / 2, height: height / 2)
            
        case .bottomRight:
            // Bottom-right quarter: x at halfway point, y at bottom of visible
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height / 2)
            
        case .nextScreen, .previousScreen, .minimize, .hide:
            // These are handled differently in moveWindow
            return screenFrame
        }
    }
    
    private func getWindowFrame(_ window: AXUIElement) -> CGRect? {
        var positionValue: AnyObject?
        var sizeValue: AnyObject?
        
        let positionResult = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        let sizeResult = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        
        guard positionResult == .success, sizeResult == .success,
              let position = positionValue, let size = sizeValue else {
            return nil
        }
        
        var point = CGPoint.zero
        var windowSize = CGSize.zero
        
        AXValueGetValue(position as! AXValue, .cgPoint, &point)
        AXValueGetValue(size as! AXValue, .cgSize, &windowSize)
        
        return CGRect(origin: point, size: windowSize)
    }
    
    private func setWindowFrame(_ window: AXUIElement, to frame: CGRect) -> Bool {
        // Validate that the frame is reasonable
        var validatedFrame = frame
        
        // Ensure the frame has positive dimensions
        if validatedFrame.width <= 0 || validatedFrame.height <= 0 {
            print("Invalid frame dimensions: \(frame)")
            return false
        }
        
        // Get window size constraints
        let constraints = getWindowSizeConstraints(window)
        
        // Apply minimum size constraints
        if let minSize = constraints.minSize {
            validatedFrame.size.width = max(validatedFrame.size.width, minSize.width)
            validatedFrame.size.height = max(validatedFrame.size.height, minSize.height)
        } else {
            // Fallback minimum size (100x100)
            validatedFrame.size.width = max(validatedFrame.size.width, 100)
            validatedFrame.size.height = max(validatedFrame.size.height, 100)
        }
        
        // Apply maximum size constraints
        if let maxSize = constraints.maxSize {
            validatedFrame.size.width = min(validatedFrame.size.width, maxSize.width)
            validatedFrame.size.height = min(validatedFrame.size.height, maxSize.height)
        }
        
        #if DEBUG
        print("Setting window frame to: \(validatedFrame)")
        if let minSize = constraints.minSize {
            print("Window min size: \(minSize)")
        }
        if let maxSize = constraints.maxSize {
            print("Window max size: \(maxSize)")
        }
        #endif
        
        // Set size first (some windows need size set before position)
        var size = validatedFrame.size
        let sizeValue = AXValueCreate(.cgSize, &size)!
        let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        
        // Then set position
        var position = validatedFrame.origin
        let positionValue = AXValueCreate(.cgPoint, &position)!
        let positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        
        #if DEBUG
        if positionResult != .success {
            print("Failed to set position: \(positionResult.rawValue)")
        }
        if sizeResult != .success {
            print("Failed to set size: \(sizeResult.rawValue)")
        }
        #endif
        
        return positionResult == .success && sizeResult == .success
    }
    
    /// Gets the minimum and maximum size constraints for a window
    private func getWindowSizeConstraints(_ window: AXUIElement) -> (minSize: CGSize?, maxSize: CGSize?) {
        var minSizeValue: AnyObject?
        var maxSizeValue: AnyObject?
        
        // Note: These attributes may not be available on all windows
        AXUIElementCopyAttributeValue(window, "AXMinSize" as CFString, &minSizeValue)
        AXUIElementCopyAttributeValue(window, "AXMaxSize" as CFString, &maxSizeValue)
        
        var minSize: CGSize?
        var maxSize: CGSize?
        
        if let minVal = minSizeValue {
            var size = CGSize.zero
            if AXValueGetValue(minVal as! AXValue, .cgSize, &size) {
                minSize = size
            }
        }
        
        if let maxVal = maxSizeValue {
            var size = CGSize.zero
            if AXValueGetValue(maxVal as! AXValue, .cgSize, &size) {
                maxSize = size
            }
        }
        
        return (minSize, maxSize)
    }
    
    // MARK: - Utility Methods
    
    /// Returns all available screens
    func getAvailableScreens() -> [NSScreen] {
        return NSScreen.screens
    }
    
    /// Returns information about all screens
    func getScreenInfo() -> [(name: String, frame: CGRect, index: Int)] {
        return NSScreen.screens.enumerated().map { index, screen in
            let name = screen.localizedName
            return (name: name, frame: screen.frame, index: index)
        }
    }
    
    /// Debug: Lists all available attributes for the frontmost window
    func debugWindowAttributes() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let app = AXUIElementCreateApplication(frontmostApp.processIdentifier) as AXUIElement?,
              let window = getFrontmostWindow(for: app) else {
            print("Failed to get frontmost window")
            return
        }
        
        var attributeNames: CFArray?
        let result = AXUIElementCopyAttributeNames(window, &attributeNames)
        
        if result == .success, let names = attributeNames as? [String] {
            print("Available window attributes:")
            for name in names.sorted() {
                var value: AnyObject?
                AXUIElementCopyAttributeValue(window, name as CFString, &value)
                print("  - \(name): \(String(describing: value))")
            }
        }
    }
}
