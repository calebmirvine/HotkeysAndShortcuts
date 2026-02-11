//
//  HotkeyDetailView.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import SwiftUI

struct HotkeyDetailView: View {
    let hotkey: HotkeyBinding
    @StateObject private var shortcutManager = ShortcutManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Image(systemName: actionIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(actionColor)
                
                VStack(alignment: .leading) {
                    Text(hotkey.shortcutName)
                        .font(.title)
                    Text(hotkey.keyComboDescription)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Toggle("Enabled", isOn: Binding(
                    get: { hotkey.isEnabled },
                    set: { shortcutManager.toggleHotkey(hotkey, enabled: $0) }
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
                        Text(actionTypeTitle)
                            .font(.headline)
                        Text(actionTypeDescription)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: hotkey.action.icon)
                        .foregroundStyle(actionColor)
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
                Button(testButtonTitle) {
                    Task {
                        await testAction()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Edit") {
                    shortcutManager.editHotkey(hotkey)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Delete", role: .destructive) {
                    shortcutManager.deleteHotkey(hotkey)
                }
                .buttonStyle(.bordered)
            }
            .padding()
        }
        .padding()
    }
    
    private var actionIcon: String {
        switch hotkey.action {
        case .shortcut:
            return "keyboard.badge.ellipsis"
        case .windowManagement:
            return "rectangle.fill.on.rectangle.fill"
        }
    }
    
    private var actionColor: Color {
        switch hotkey.action {
        case .shortcut:
            return .orange
        case .windowManagement:
            return .blue
        }
    }
    
    private var actionTypeTitle: String {
        switch hotkey.action {
        case .shortcut:
            return "Apple Shortcut"
        case .windowManagement:
            return "Window Position"
        }
    }
    
    private var actionTypeDescription: String {
        switch hotkey.action {
        case .shortcut(let name):
            return name
        case .windowManagement(let position):
            return position.displayName
        }
    }
    
    private var testButtonTitle: String {
        switch hotkey.action {
        case .shortcut:
            return "Test Shortcut"
        case .windowManagement(let position):
            switch position {
            case .minimize:
                return "Test Minimize"
            case .hide:
                return "Test Hide"
            default:
                return "Test Window Move"
            }
        }
    }
    
    private func testAction() async {
        switch hotkey.action {
        case .shortcut(let name):
            await shortcutManager.runShortcut(named: name)
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
