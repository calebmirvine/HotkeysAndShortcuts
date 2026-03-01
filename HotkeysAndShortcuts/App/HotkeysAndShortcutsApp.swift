//
//  HotkeysAndShortcutsApp.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import SwiftUI

/// Main app entry point
@main
struct HotkeysAndShortcutsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Menu bar apps don't need any scenes
        // All windows are managed by the AppDelegate
        Settings {
            EmptyView()
        }
        .defaultSize(width: 0, height: 0)
        .windowStyle(.hiddenTitleBar)
    }
}

