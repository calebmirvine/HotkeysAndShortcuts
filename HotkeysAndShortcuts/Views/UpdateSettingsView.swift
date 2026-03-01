//
//  UpdateSettingsView.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-02-28.
//

import SwiftUI

/// Update settings tab for managing automatic updates
struct UpdateSettingsView: View {
    @ObservedObject private var updateManager = UpdateManager.shared
    
    var body: some View {
        Form {
            updateSection
            preferencesSection
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Sections
    
    private var updateSection: some View {
        Section {
            Button("Check for Updates Now") {
                updateManager.checkForUpdates()
            }
            .disabled(!updateManager.canCheckForUpdates)
            
            Text("Automatically checks for updates in the background and notifies you when a new version is available.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Updates")
        }
    }
    
    private var preferencesSection: some View {
        Section {
            Toggle("Automatically Check for Updates", isOn: Binding(
                get: { updateManager.automaticallyChecksForUpdates },
                set: { updateManager.setAutomaticallyChecksForUpdates($0) }
            ))
            .help("Periodically check for new versions in the background")
            
            Toggle("Automatically Download Updates", isOn: Binding(
                get: { updateManager.automaticallyDownloadsUpdates },
                set: { updateManager.setAutomaticallyDownloadsUpdates($0) }
            ))
            .help("Download updates automatically when available (you'll still be prompted before installing)")
        } header: {
            Text("Preferences")
        }
    }
}

#Preview {
    UpdateSettingsView()
        .frame(width: 500, height: 300)
}
