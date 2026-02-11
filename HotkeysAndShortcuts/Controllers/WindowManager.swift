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
        
        if canMinimizeResult == .success, let minimizeButton = canMinimize as! AXUIElement? {
            // Press the minimize button
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
    
    // MARK: - Helper Methods
    
    private func getFrontmostWindow(for app: AXUIElement) -> AXUIElement? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &value)
        
        if result == .success, let window = value {
            return (window as! AXUIElement)
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
        return screen.visibleFrame
    }
    
    private func calculateFrame(for position: WindowPosition, in screenFrame: CGRect) -> CGRect {
        let x = screenFrame.origin.x
        let y = screenFrame.origin.y
        let width = screenFrame.width
        let height = screenFrame.height
        
        switch position {
        case .leftHalf:
            return CGRect(x: x, y: y, width: width / 2, height: height)
            
        case .rightHalf:
            return CGRect(x: x + width / 2, y: y, width: width / 2, height: height)
            
        case .topHalf:
            return CGRect(x: x, y: y + height / 2, width: width, height: height / 2)
            
        case .bottomHalf:
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
            return CGRect(x: x, y: y + height / 2, width: width / 2, height: height / 2)
            
        case .topRight:
            return CGRect(x: x + width / 2, y: y + height / 2, width: width / 2, height: height / 2)
            
        case .bottomLeft:
            return CGRect(x: x, y: y, width: width / 2, height: height / 2)
            
        case .bottomRight:
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
        // Set position
        var position = frame.origin
        let positionValue = AXValueCreate(.cgPoint, &position)!
        let positionResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
        
        // Set size
        var size = frame.size
        let sizeValue = AXValueCreate(.cgSize, &size)!
        let sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
        
        return positionResult == .success && sizeResult == .success
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
}
