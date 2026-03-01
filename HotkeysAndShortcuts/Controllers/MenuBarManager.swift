//
//  MenuBarManager.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import AppKit
import SwiftUI

/// Manages the menu bar (status bar) item and its interactions
@MainActor
class MenuBarManager {
    static let shared = MenuBarManager()
    
    private var statusItem: NSStatusItem?
    weak var windowController: MainWindowController?
    
    private init() {
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "keyboard.badge.ellipsis",
                accessibilityDescription: "Hotkeys & Shortcuts"
            )
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            windowController?.toggleMainWindow()
        }
    }
    
    private func showMenu() {
        let menu = NSMenu()
        
        let showItem = NSMenuItem(
            title: "Show Shortcuts",
            action: #selector(showMainWindow),
            keyEquivalent: ""
        )
        showItem.target = self
        menu.addItem(showItem)
        menu.addItem(NSMenuItem.separator())
        
        // Launch at Login toggle
        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = LaunchAtLoginManager.shared.isEnabled ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Auto-update settings
        let autoUpdateItem = NSMenuItem(
            title: "Check for Updates Automatically",
            action: #selector(toggleAutoUpdate),
            keyEquivalent: ""
        )
        autoUpdateItem.target = self
        autoUpdateItem.state = UpdateManager.shared.automaticallyChecksForUpdates ? .on : .off
        menu.addItem(autoUpdateItem)
        
        let checkUpdatesItem = NSMenuItem(
            title: "Check for Updates Now...",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        checkUpdatesItem.target = self
        menu.addItem(checkUpdatesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let accessibilityPermissionsItem = NSMenuItem(
            title: "Check Accessibility Permissions...",
            action: #selector(checkAccessibilityPermissions),
            keyEquivalent: ""
        )
        accessibilityPermissionsItem.target = self
        menu.addItem(accessibilityPermissionsItem)
        
        let appleScriptPermissionsItem = NSMenuItem(
            title: "Check AppleScript Permissions...",
            action: #selector(checkAppleScriptPermissions),
            keyEquivalent: ""
        )
        appleScriptPermissionsItem.target = self
        menu.addItem(appleScriptPermissionsItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(
            title: "Quit",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc private func toggleLaunchAtLogin() {
        LaunchAtLoginManager.shared.isEnabled.toggle()
    }
    
    @objc private func showMainWindow() {
        windowController?.showMainWindow()
    }
    
    @objc private func toggleAutoUpdate() {
        UpdateManager.shared.automaticallyChecksForUpdates.toggle()
    }
    
    @objc private func checkForUpdates() {
        UpdateManager.shared.checkForUpdates()
    }
    
    @objc private func checkAccessibilityPermissions() {
        ShortcutManager.shared.requestAccessibilityPermissions(showSuccessAlert: true)
    }
    
    @objc private func checkAppleScriptPermissions() {
        ShortcutManager.shared.checkAppleScriptPermissions()
    }
}
