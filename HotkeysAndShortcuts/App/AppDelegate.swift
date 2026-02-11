//
//  AppDelegate.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import AppKit
import SwiftUI

/// Main application delegate that manages app lifecycle and core functionality
class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindowController: MainWindowController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock - run as menu bar app
        NSApplication.shared.setActivationPolicy(.accessory)
        
        // Setup main window controller
        mainWindowController = MainWindowController()
        MenuBarManager.shared.windowController = mainWindowController
        
        // Request accessibility permissions on launch
        Task { @MainActor in
            ShortcutManager.shared.requestAccessibilityPermissions()
            
            // Offer to enable launch at login on first run
            await offerLaunchAtLogin()
        }
    }
    
    /// Offers to enable launch at login if this is the first time the app is run
    @MainActor
    private func offerLaunchAtLogin() async {
        let hasAskedBefore = UserDefaults.standard.bool(forKey: "hasAskedLaunchAtLogin")
        
        // Only ask once, on first launch
        guard !hasAskedBefore else { return }
        
        // Mark that we've asked
        UserDefaults.standard.set(true, forKey: "hasAskedLaunchAtLogin")
        
        // Don't ask if already enabled
        guard !LaunchAtLoginManager.shared.isEnabled else { return }
        
        // Wait a bit so we don't show too many dialogs at once
        try? await Task.sleep(for: .seconds(1))
        
        // Ask the user
        let _ = await LaunchAtLoginManager.shared.requestEnable()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep the app running even if windows are closed (menu bar app behavior)
        return false
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Check if user has disabled quit confirmation
        let confirmQuit = UserDefaults.standard.object(forKey: "confirmQuit") as? Bool ?? true
        
        if !confirmQuit {
            return .terminateNow
        }
        
        // Show confirmation dialog when user tries to quit
        let alert = NSAlert()
        alert.messageText = "Quit Hotkeys & Shortcuts?"
        alert.informativeText = "Your keyboard shortcuts will stop working until you launch the app again.\n\nThe app will automatically start when you log in next time."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Keep Running")
        alert.icon = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Warning")
        alert.showsSuppressionButton = true
        alert.suppressionButton?.title = "Don't ask again"
        
        let response = alert.runModal()
        
        // Save preference if user checked "Don't ask again"
        if alert.suppressionButton?.state == .on {
            UserDefaults.standard.set(false, forKey: "confirmQuit")
        }
        
        return response == .alertFirstButtonReturn ? .terminateNow : .terminateCancel
    }
}
