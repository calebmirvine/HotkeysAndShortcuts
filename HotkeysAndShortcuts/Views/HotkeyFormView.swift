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
    @State private var appleScriptCode = ""
    @State private var swiftExpressionCode = ""
    @State private var keyRecorder = KeyRecorder()
    
    private var isEditMode: Bool { hotkey != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                if !isEditMode {
                    actionTypeSection
                    
                    switch actionType {
                    case .shortcut:
                        shortcutSelectionSection
                    case .windowManagement:
                        windowPositionSection
                    case .appleScript:
                        appleScriptSection
                    case .swiftExpression:
                        swiftExpressionSection
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
    
    /// AppleScript code editor (add mode, appleScript type)
    private var appleScriptSection: some View {
        Section("AppleScript Code") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter your AppleScript code:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $appleScriptCode)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 150)
                    .border(Color.secondary.opacity(0.3), width: 1)
                
                Text("Example: tell application \"Music\" to playpause")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Test Run") {
                    testAppleScript()
                }
                .buttonStyle(.bordered)
                .disabled(appleScriptCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 4)
        }
    }
    
    /// Swift expression editor (add mode, swift type)
    private var swiftExpressionSection: some View {
        Section("Swift Expression") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter a Swift expression to evaluate:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $swiftExpressionCode)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 100)
                    .border(Color.secondary.opacity(0.3), width: 1)
                
                Text("Example: 2 + 2 * 5")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button("Test Run") {
                    testSwiftExpression()
                }
                .buttonStyle(.bordered)
                .disabled(swiftExpressionCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Logic
    
    private var canSave: Bool {
        guard keyRecorder.hasValidKeyCombination else { return false }
        if isEditMode { return true }
        
        switch actionType {
        case .shortcut:
            return !selectedShortcut.isEmpty
        case .windowManagement:
            return true
        case .appleScript:
            return !appleScriptCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .swiftExpression:
            return !swiftExpressionCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    private func save() {
        if keyRecorder.isRecording { keyRecorder.stopRecording() }
        
        if let existing = hotkey {
            manager.updateHotkey(existing, keyCode: keyRecorder.keyCode, modifiers: keyRecorder.modifiers)
        } else {
            let action: HotkeyAction
            switch actionType {
            case .shortcut:
                action = .shortcut(name: selectedShortcut)
            case .windowManagement:
                action = .windowManagement(position: selectedPosition)
            case .appleScript:
                action = .appleScript(script: appleScriptCode)
            case .swiftExpression:
                action = .swiftExpression(expression: swiftExpressionCode)
            }
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
    
    private func testAppleScript() {
        Task {
            await manager.executeAppleScript(appleScriptCode)
        }
    }
    
    private func testSwiftExpression() {
        Task {
            await manager.executeSwiftExpression(swiftExpressionCode)
        }
    }
}

// MARK: - Action Type

/// Type of action to assign to hotkey
enum ActionType: String, CaseIterable {
    case shortcut = "Shortcut"
    case windowManagement = "Window"
    case appleScript = "AppleScript"
    case swiftExpression = "Swift"
    
    var icon: String {
        switch self {
        case .shortcut: return "arrow.triangle.turn.up.right.diamond.fill"
        case .windowManagement: return "rectangle.fill.on.rectangle.fill"
        case .appleScript: return "applescript"
        case .swiftExpression: return "chevron.left.forwardslash.chevron.right"
        }
    }
    
    var color: Color {
        switch self {
        case .shortcut: return .orange
        case .windowManagement: return .blue
        case .appleScript: return .purple
        case .swiftExpression: return .green
        }
    }
    
    var description: String {
        switch self {
        case .shortcut: return "Execute an Apple Shortcut"
        case .windowManagement: return "Move or resize the active window"
        case .appleScript: return "Execute custom AppleScript code"
        case .swiftExpression: return "Evaluate a Swift expression"
        }
    }
}
