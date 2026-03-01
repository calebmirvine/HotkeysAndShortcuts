//
//  HotkeyFormView.swift
//  HotkeysAndShortcuts
//
//  Unified view for adding new hotkeys or editing existing ones
//

import SwiftUI

/// Form for creating or editing hotkey bindings
struct HotkeyFormView: View {
    let hotkey: HotkeyBinding? // nil = add mode, non-nil = edit mode
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = ShortcutManager.shared
    
    @State private var actionType: ActionType = .shortcut
    @State private var selectedShortcut = ""
    @State private var availableShortcuts: [String] = []
    @State private var isLoadingShortcuts = true
    @State private var selectedPosition: WindowPosition = .leftHalf
    @State private var keyRecorder = KeyRecorder()
    
    private var isEditMode: Bool { hotkey != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                if !isEditMode {
                    actionTypeSection
                    
                    if actionType == .shortcut {
                        shortcutSelectionSection
                    } else {
                        windowPositionSection
                    }
                } else {
                    currentHotkeySection
                }
                
                keyRecorderSection
            }
            .formStyle(.grouped)
            .navigationTitle(isEditMode ? "Edit Hotkey" : "Add Hotkey")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Save" : "Add") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if !isEditMode && actionType == .shortcut {
                    loadShortcuts()
                }
            }
            .onChange(of: actionType) { _, new in
                if new == .shortcut && availableShortcuts.isEmpty {
                    loadShortcuts()
                }
            }
            .onDisappear {
                if keyRecorder.isRecording { keyRecorder.stopRecording() }
            }
        }
        .frame(minWidth: 500, minHeight: isEditMode ? 300 : 450)
    }
    
    // MARK: - Sections
    
    /// Key recorder controls
    private var keyRecorderSection: some View {
        Section("Assign Keyboard Shortcut") {
            HStack {
                Text("Press keys:")
                Spacer()
                Text(keyRecorder.keyComboDescription.isEmpty ? "No keys recorded" : keyRecorder.keyComboDescription)
                    .foregroundStyle(keyRecorder.keyComboDescription.isEmpty ? .secondary : .primary)
                    .font(.system(.body, design: .monospaced))
            }
            
            Button(keyRecorder.isRecording ? "Recording... (Press Escape to cancel)" : "Record Key Combination") {
                if keyRecorder.isRecording {
                    keyRecorder.stopRecording()
                } else {
                    keyRecorder.startRecording()
                }
            }
            .buttonStyle(.bordered)
            
            if !keyRecorder.keyComboDescription.isEmpty {
                Button("Clear") { keyRecorder.clear() }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
            }
        }
    }
    
    /// Current hotkey info (edit mode only)
    private var currentHotkeySection: some View {
        Section("Current Hotkey") {
            LabeledContent("Action", value: hotkey?.action.displayName ?? "")
            LabeledContent("Keys", value: hotkey?.keyComboDescription ?? "")
        }
    }
    
    /// Action type picker (add mode only)
    private var actionTypeSection: some View {
        Section("Action Type") {
            Picker("Type", selection: $actionType) {
                ForEach(ActionType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            HStack(spacing: 12) {
                Image(systemName: actionType.icon)
                    .font(.title2)
                    .foregroundStyle(actionType.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(actionType.rawValue)
                        .font(.headline)
                    Text(actionType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    /// Shortcut selection (add mode, shortcut type)
    private var shortcutSelectionSection: some View {
        Section("Select Apple Shortcut") {
            if isLoadingShortcuts {
                HStack {
                    ProgressView().controlSize(.small)
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
    }
    
    /// Window position selection (add mode, window type)
    private var windowPositionSection: some View {
        Section("Window Position") {
            Picker("Position", selection: $selectedPosition) {
                ForEach(WindowPosition.allCases, id: \.self) { position in
                    Label(position.displayName, systemImage: position.systemImage)
                        .tag(position)
                }
            }
            .pickerStyle(.menu)
            
            HStack {
                Image(systemName: selectedPosition.systemImage)
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading) {
                    Text(selectedPosition.displayName)
                        .font(.headline)
                    Text(HotkeyAction.windowManagement(position: selectedPosition).description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Logic
    
    private var canSave: Bool {
        guard keyRecorder.hasValidKeyCombination else { return false }
        return isEditMode || (actionType == .shortcut ? !selectedShortcut.isEmpty : true)
    }
    
    private func save() {
        if keyRecorder.isRecording { keyRecorder.stopRecording() }
        
        if let existing = hotkey {
            manager.updateHotkey(existing, keyCode: keyRecorder.keyCode, modifiers: keyRecorder.modifiers)
        } else {
            let action: HotkeyAction = actionType == .shortcut
                ? .shortcut(name: selectedShortcut)
                : .windowManagement(position: selectedPosition)
            manager.addHotkey(action: action, keyCode: keyRecorder.keyCode, modifiers: keyRecorder.modifiers)
        }
        dismiss()
    }
    
    private func loadShortcuts() {
        Task {
            isLoadingShortcuts = true
            let shortcuts = await manager.fetchAvailableShortcuts()
            await MainActor.run {
                availableShortcuts = shortcuts
                isLoadingShortcuts = false
            }
        }
    }
}

// MARK: - Action Type

/// Type of action to assign to hotkey
enum ActionType: String, CaseIterable {
    case shortcut = "Run Shortcut"
    case windowManagement = "Move Window"
    
    var icon: String {
        switch self {
        case .shortcut: return "arrow.triangle.turn.up.right.diamond.fill"
        case .windowManagement: return "rectangle.fill.on.rectangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .shortcut: return .orange
        case .windowManagement: return .blue
        }
    }
    
    var description: String {
        switch self {
        case .shortcut: return "Execute an Apple Shortcut"
        case .windowManagement: return "Move or resize the active window"
        }
    }
}
