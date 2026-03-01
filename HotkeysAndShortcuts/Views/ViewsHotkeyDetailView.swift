//
//  HotkeyDetailView.swift
//  HotkeysAndShortcuts
//
//  Detail view showing hotkey information and actions
//

import SwiftUI

/// Displays detailed information about a hotkey binding
struct HotkeyDetailView: View {
    let hotkey: HotkeyBinding
    @StateObject private var manager = ShortcutManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: hotkey.action.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(hotkey.action.color)
                
                VStack(alignment: .leading) {
                    Text(hotkey.action.displayName)
                        .font(.title)
                    Text(hotkey.keyComboDescription)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("Enabled", isOn: Binding(
                    get: { hotkey.isEnabled },
                    set: { manager.toggleHotkey(hotkey, enabled: $0) }
                ))
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Divider()
            
            // Details
            VStack(alignment: .leading, spacing: 12) {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(hotkey.action.typeTitle)
                            .font(.headline)
                        Text(hotkey.action.displayName)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: hotkey.action.icon)
                        .foregroundStyle(hotkey.action.color)
                }
                
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Key Combination")
                            .font(.headline)
                        Text(hotkey.keyComboDescription)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "command")
                        .foregroundStyle(.blue)
                }
                
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Priority")
                            .font(.headline)
                        Text("High (overrides other apps)")
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }
            .padding()
            
            Spacer()
            
            // Actions
            HStack {
                Button(hotkey.action.testButtonTitle) {
                    Task { await testAction() }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Edit") {
                    manager.editHotkey(hotkey)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Delete", role: .destructive) {
                    manager.deleteHotkey(hotkey)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .padding()
    }
    
    /// Executes the hotkey action for testing
    private func testAction() async {
        switch hotkey.action {
        case .shortcut(let name):
            await manager.runShortcut(named: name)
        case .windowManagement(let position):
            let success: Bool
            switch position {
            case .nextScreen:
                success = WindowManager.shared.moveWindowToNextScreen()
            case .previousScreen:
                success = WindowManager.shared.moveWindowToPreviousScreen()
            case .minimize:
                success = WindowManager.shared.minimizeWindow()
            case .hide:
                success = WindowManager.shared.hideApplication()
            default:
                success = WindowManager.shared.moveWindow(to: position)
            }
            
            if !success {
                // Could show an alert here
                print("Failed to perform window action")
            }
        }
    }
}
