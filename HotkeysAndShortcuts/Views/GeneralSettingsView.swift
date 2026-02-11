//
//  GeneralSettingsView.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import SwiftUI
import ServiceManagement

/// General settings tab with preferences and permissions
struct GeneralSettingsView: View {
    @StateObject private var launchManager = LaunchAtLoginManager.shared
    @AppStorage("showNotifications") private var showNotifications = true
    @AppStorage("confirmQuit") private var confirmQuit = true
    
    var body: some View {
        Form {
            preferencesSection
            permissionsSection
            
            if #available(macOS 13.0, *) {
                statusSection
            }
        }
        .formStyle(.grouped)
        .padding()
    }
    
    // MARK: - Sections
    
    private var preferencesSection: some View {
        Section {
            Toggle("Launch at Login", isOn: $launchManager.isEnabled)
                .help("Automatically start Hotkeys & Shortcuts when you log in to your Mac")
            
            Toggle("Show Notifications", isOn: $showNotifications)
                .help("Show notifications when shortcuts are executed")
            
            Toggle("Confirm Before Quitting", isOn: $confirmQuit)
                .help("Show a confirmation dialog when quitting the app")
        } header: {
            Text("General")
        }
    }
    
    private var permissionsSection: some View {
        Section {
            Button("Check Accessibility Permissions") {
                ShortcutManager.shared.requestAccessibilityPermissions()
            }
            
            Text("This app requires Accessibility permissions to capture global keyboard shortcuts.")
                .font(.caption)
                .foregroundStyle(.secondary)
        } header: {
            Text("Permissions")
        }
    }
    
    @available(macOS 13.0, *)
    private var statusSection: some View {
        Section {
            HStack {
                Image(systemName: launchAtLoginStatusIcon)
                    .foregroundStyle(launchAtLoginStatusColor)
                Text(launchAtLoginStatusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Status")
        }
    }
    
    // MARK: - Launch at Login Status
    
    @available(macOS 13.0, *)
    private var launchAtLoginStatusIcon: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "checkmark.circle.fill"
        case .notRegistered, .notFound:
            return "circle"
        case .requiresApproval:
            return "exclamationmark.triangle.fill"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    @available(macOS 13.0, *)
    private var launchAtLoginStatusColor: Color {
        switch SMAppService.mainApp.status {
        case .enabled:
            return .green
        case .notRegistered, .notFound:
            return .secondary
        case .requiresApproval:
            return .orange
        @unknown default:
            return .secondary
        }
    }
    
    @available(macOS 13.0, *)
    private var launchAtLoginStatusText: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "Launch at login is enabled"
        case .notRegistered:
            return "Launch at login is not registered"
        case .notFound:
            return "Launch helper not found"
        case .requiresApproval:
            return "Launch at login requires approval in System Settings"
        @unknown default:
            return "Unknown status"
        }
    }
}

#Preview {
    GeneralSettingsView()
        .frame(width: 500, height: 300)
}
