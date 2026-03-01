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
    
    @Published private(set) var canCheckForUpdates = false
    
    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set {
            Task { @MainActor in
                updaterController.updater.automaticallyChecksForUpdates = newValue
            }
        }
    }
    
    var automaticallyDownloadsUpdates: Bool {
        get { updaterController.updater.automaticallyDownloadsUpdates }
        set {
            Task { @MainActor in
                updaterController.updater.automaticallyDownloadsUpdates = newValue
            }
        }
    }
    
    private init() {
        // Initialize Sparkle with standard user driver
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        // Set up update preferences
        canCheckForUpdates = updaterController.updater.canCheckForUpdates
    }
    
    /// Check for updates manually
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
    

}
