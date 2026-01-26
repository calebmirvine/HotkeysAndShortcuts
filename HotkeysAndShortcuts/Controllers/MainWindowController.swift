//
//  MainWindowController.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import AppKit
import SwiftUI

/// Manages the main shortcuts window
@MainActor
class MainWindowController {
    private var mainWindow: NSWindow?
    
    /// Toggles the main window visibility
    func toggleMainWindow() {
        // Guard against accessing deallocated window
        guard let window = mainWindow else {
            showMainWindow()
            return
        }
        
        if window.isVisible {
            window.orderOut(nil)
        } else {
            showMainWindow()
        }
    }
    
    /// Shows the main window
    func showMainWindow() {
        if mainWindow == nil {
            createMainWindow()
        }
        
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func createMainWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Hotkeys & Shortcuts"
        window.contentView = NSHostingView(rootView: HotkeysAndShortcuts.ContentView())
        
        // Prevent window from being released when closed
        window.isReleasedWhenClosed = false
        
        // Always center the window on screen (removes autosave behavior)
        window.center()
        
        mainWindow = window
    }
}
