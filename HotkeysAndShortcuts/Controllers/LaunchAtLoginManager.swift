//
//  LaunchAtLoginManager.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import Foundation
import ServiceManagement
import SwiftUI
import Combine

/// Manages the launch-at-login functionality for the app
@MainActor
class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    
    @Published var isEnabled: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Check current status
        self.isEnabled = Self.getCurrentStatus()
        
        // Observe changes to isEnabled
        $isEnabled
            .dropFirst() // Skip the initial value
            .removeDuplicates()
            .sink { [weak self] newValue in
                self?.updateLaunchAtLogin(enabled: newValue)
            }
            .store(in: &cancellables)
    }
    
    /// Gets the current launch-at-login status
    static func getCurrentStatus() -> Bool {
        // For macOS 13+, use the modern ServiceManagement API
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // For older macOS versions, check UserDefaults as a fallback
            return UserDefaults.standard.bool(forKey: "launchAtLogin")
        }
    }
    
    /// Enables or disables launch at login
    private func updateLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status == .enabled {
                        print("Launch at login already enabled")
                    } else {
                        try SMAppService.mainApp.register()
                        print("Launch at login enabled successfully")
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                        print("Launch at login disabled successfully")
                    } else {
                        print("Launch at login already disabled")
                    }
                }
                
                // Sync with UserDefaults
                UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
                
            } catch {
                print("Failed to update launch at login: \(error.localizedDescription)")
                
                // Revert the state if it failed
                Task { @MainActor in
                    self.isEnabled = !enabled
                }
                
                // Show error to user
                showError(error)
            }
        } else {
            // For older macOS, just store in UserDefaults
            // Note: Full functionality requires macOS 13+
            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
            print("Launch at login preference saved (requires macOS 13+ for automatic launch)")
        }
    }
    
    /// Request to enable launch at login with user confirmation
    func requestEnable() async -> Bool {
        guard !isEnabled else { return true }
        
        let shouldEnable = await showEnableDialog()
        
        if shouldEnable {
            isEnabled = true
            return isEnabled
        }
        
        return false
    }
    
    /// Shows a dialog asking the user if they want to enable launch at login
    @MainActor
    private func showEnableDialog() async -> Bool {
        let alert = NSAlert()
        alert.messageText = "Launch at Login"
        alert.informativeText = "Would you like Hotkeys & Shortcuts to launch automatically when you start your Mac? This ensures your custom keyboard shortcuts are always available."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Enable")
        alert.addButton(withTitle: "Not Now")
        
        let response = alert.runModal()
        return response == .alertFirstButtonReturn
    }
    
    /// Shows an error dialog when launch-at-login setup fails
    @MainActor
    private func showError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Launch at Login Error"
        alert.informativeText = "Failed to update launch at login setting: \(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
