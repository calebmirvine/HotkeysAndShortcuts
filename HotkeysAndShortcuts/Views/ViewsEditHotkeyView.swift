//
//  EditHotkeyView.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import SwiftUI

struct EditHotkeyView: View {
    let hotkey: HotkeyBinding
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shortcutManager = ShortcutManager.shared
    
    @State private var keyRecorder = KeyRecorder()
    @State private var isRecording = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Shortcut") {
                    LabeledContent("Name", value: hotkey.shortcutName)
                    LabeledContent("Current Keys", value: hotkey.keyComboDescription)
                }
                
                Section("New Key Combination") {
                    HStack {
                        Text("Press keys:")
                        Spacer()
                        Text(keyRecorder.keyComboDescription.isEmpty ? "No keys recorded" : keyRecorder.keyComboDescription)
                            .foregroundStyle(keyRecorder.keyComboDescription.isEmpty ? .secondary : .primary)
                            .font(.system(.body, design: .monospaced))
                    }
                    
                    Button(isRecording ? "Recording... (Press Escape to cancel)" : "Record New Key Combination") {
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
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Keyboard Shortcut")
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
                    Button("Save") {
                        // Ensure recording is stopped before saving
                        if isRecording {
                            keyRecorder.stopRecording()
                        }
                        updateHotkey()
                    }
                    .disabled(!keyRecorder.hasValidKeyCombination)
                }
            }
            .onDisappear {
                // Clean up: ensure recording is stopped and monitoring is resumed
                if isRecording {
                    keyRecorder.stopRecording()
                }
            }
        }
        .frame(minWidth: 500, minHeight: 300)
    }
    
    private func updateHotkey() {
        shortcutManager.updateHotkey(
            hotkey,
            keyCode: keyRecorder.keyCode,
            modifiers: keyRecorder.modifiers
        )
        dismiss()
    }
}
