//
//  AddHotkeyView.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import SwiftUI

struct AddHotkeyView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shortcutManager = ShortcutManager.shared
    
    enum ActionType: String, CaseIterable {
        case shortcut = "Run Shortcut"
        case windowManagement = "Move Window"
    }
    
    @State private var selectedActionType: ActionType = .shortcut
    
    @State private var selectedShortcut: String = ""
    @State private var availableShortcuts: [String] = []
    @State private var isLoadingShortcuts = true
    
    @State private var selectedWindowPosition: WindowPosition = .leftHalf
    
    @State private var keyRecorder = KeyRecorder()
    @State private var isRecording = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Action Type") {
                    Picker("Type", selection: $selectedActionType) {
                        ForEach(ActionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // Visual indicator with icons
                    HStack(spacing: 12) {
                        Image(systemName: selectedActionType == .shortcut ? 
                              "arrow.triangle.turn.up.right.diamond.fill" : 
                              "rectangle.fill.on.rectangle.fill")
                            .font(.title2)
                            .foregroundStyle(selectedActionType == .shortcut ? .orange : .blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedActionType.rawValue)
                                .font(.headline)
                            Text(selectedActionType == .shortcut ? 
                                 "Execute an Apple Shortcut" :
                                 "Move or resize the active window")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if selectedActionType == .shortcut {
                    Section("Select Apple Shortcut") {
                        if isLoadingShortcuts {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Loading shortcuts...")
                                    .foregroundStyle(.secondary)
                            }
                        } else if availableShortcuts.isEmpty {
                            Text("No shortcuts found. Create shortcuts in the Shortcuts app first.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Shortcut", selection: $selectedShortcut) {
                                Text("Select a shortcut...").tag("")
                                ForEach(availableShortcuts, id: \.self) { shortcut in
                                    Text(shortcut).tag(shortcut)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                } else {
                    Section("Select Window Position") {
                        Picker("Position", selection: $selectedWindowPosition) {
                            ForEach(WindowPosition.allCases, id: \.self) { position in
                                Label(position.displayName, systemImage: position.systemImage)
                                    .tag(position)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        // Preview of selected position
                        HStack {
                            Image(systemName: selectedWindowPosition.systemImage)
                                .font(.largeTitle)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(selectedWindowPosition.displayName)
                                    .font(.headline)
                                Text(positionDescription(for: selectedWindowPosition))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Assign Keyboard Shortcut") {
                    HStack {
                        Text("Press keys:")
                        Spacer()
                        Text(keyRecorder.keyComboDescription.isEmpty ? "No keys recorded" : keyRecorder.keyComboDescription)
                            .foregroundStyle(keyRecorder.keyComboDescription.isEmpty ? .secondary : .primary)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    Button(isRecording ? "Recording... (Press Escape to cancel)" : "Record Key Combination") {
                        if isRecording {
                            keyRecorder.stopRecording()
                            isRecording = false
                        } else {
                            keyRecorder.startRecording()
                            isRecording = true
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    if !keyRecorder.keyComboDescription.isEmpty {
                        Button("Clear") {
                            keyRecorder.clear()
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Text(selectedActionType == .shortcut ? 
                         "This shortcut will have priority over other apps' shortcuts." :
                         "This hotkey will move the frontmost window to the selected position.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Keyboard Shortcut")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Ensure recording is stopped when canceling
                        if isRecording {
                            keyRecorder.stopRecording()
                        }
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        // Ensure recording is stopped before adding
                        if isRecording {
                            keyRecorder.stopRecording()
                        }
                        addHotkey()
                    }
                    .disabled(!canAddHotkey)
                }
            }
            .onAppear {
                if selectedActionType == .shortcut {
                    loadAvailableShortcuts()
                }
            }
            .onChange(of: selectedActionType) { _, newValue in
                if newValue == .shortcut && availableShortcuts.isEmpty && !isLoadingShortcuts {
                    loadAvailableShortcuts()
                }
            }
            .onDisappear {
                // Clean up: ensure recording is stopped and monitoring is resumed
                if isRecording {
                    keyRecorder.stopRecording()
                }
            }
        }
        .frame(minWidth: 500, minHeight: 450)
    }
    
    private var canAddHotkey: Bool {
        let hasValidAction: Bool
        
        switch selectedActionType {
        case .shortcut:
            hasValidAction = !selectedShortcut.isEmpty
        case .windowManagement:
            hasValidAction = true // Always valid if a position is selected
        }
        
        return hasValidAction && keyRecorder.hasValidKeyCombination
    }
    
    private func positionDescription(for position: WindowPosition) -> String {
        switch position {
        case .leftHalf: return "Snap to left 50% of screen"
        case .rightHalf: return "Snap to right 50% of screen"
        case .topHalf: return "Snap to top 50% of screen"
        case .bottomHalf: return "Snap to bottom 50% of screen"
        case .topLeft: return "Snap to top-left corner (25%)"
        case .topRight: return "Snap to top-right corner (25%)"
        case .bottomLeft: return "Snap to bottom-left corner (25%)"
        case .bottomRight: return "Snap to bottom-right corner (25%)"
        case .fullScreen, .maximize: return "Fill entire screen"
        case .center: return "Center at 70% size"
        case .nextScreen: return "Move to next display"
        case .previousScreen: return "Move to previous display"
        case .minimize: return "Minimize window to Dock"
        case .hide: return "Hide the application"
        }
    }
    
    private func loadAvailableShortcuts() {
        Task {
            isLoadingShortcuts = true
            let shortcuts = await shortcutManager.fetchAvailableShortcuts()
            await MainActor.run {
                availableShortcuts = shortcuts
                isLoadingShortcuts = false
            }
        }
    }
    
    private func addHotkey() {
        let action: HotkeyAction
        
        switch selectedActionType {
        case .shortcut:
            action = .shortcut(name: selectedShortcut)
        case .windowManagement:
            action = .windowManagement(position: selectedWindowPosition)
        }
        
        shortcutManager.addHotkey(
            action: action,
            keyCode: keyRecorder.keyCode,
            modifiers: keyRecorder.modifiers
        )
        dismiss()
    }
}
