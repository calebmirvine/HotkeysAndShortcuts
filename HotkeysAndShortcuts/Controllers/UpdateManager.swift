//
//  UpdateManager.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-02-28.
//

import Foundation
import Sparkle
import Combine

/// Manages automatic updates using Sparkle framework
class UpdateManager: ObservableObject {
    static let shared = UpdateManager()
    
    private let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates = false
    @Published var automaticallyChecksForUpdates = true
    @Published var automaticallyDownloadsUpdates = false
    
    private init() {
        // Initialize Sparkle with standard user driver
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        // Set up update preferences
        let updater = updaterController.updater
        canCheckForUpdates = updater.canCheckForUpdates
        automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        automaticallyDownloadsUpdates = updater.automaticallyDownloadsUpdates
    }
    
    /// Check for updates manually
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
    
    /// Update automatic check preference
    func setAutomaticallyChecksForUpdates(_ value: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = value
        automaticallyChecksForUpdates = value
    }
    
    /// Update automatic download preference
    func setAutomaticallyDownloadsUpdates(_ value: Bool) {
        updaterController.updater.automaticallyDownloadsUpdates = value
        automaticallyDownloadsUpdates = value
    }
}
