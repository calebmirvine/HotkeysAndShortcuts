//
//  ContentView.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import SwiftUI
import AppIntents
import Combine

struct ContentView: View {
    @StateObject private var shortcutManager = ShortcutManager.shared
    @State private var isAddingHotkey = false
    @State private var hasAccessibilityPermissions = false
    @State private var permissionCheckTimer: Timer?
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // Sidebar with list of shortcuts
            VStack(spacing: 0) {
                // Accessibility warning banner
                if !hasAccessibilityPermissions {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Accessibility Permission Required")
                                .font(.headline)
                        }
                        
                        Text("Keyboard shortcuts won't work without accessibility permissions.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Grant Permission") {
                            shortcutManager.requestAccessibilityPermissions()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding([.horizontal, .top])
                }
                
                List(selection: $shortcutManager.selectedHotkeyID) {
                    ForEach(shortcutManager.hotkeys) { hotkey in
                        HotkeyRow(hotkey: hotkey)
                            .tag(hotkey.id)
                            .contextMenu {
                                Button("Edit") {
                                    shortcutManager.editHotkey(hotkey)
                                }
                                Button("Delete", role: .destructive) {
                                    shortcutManager.deleteHotkey(hotkey)
                                }
                            }
                    }
                }
            }
            .navigationTitle("Keyboard Shortcuts")
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isAddingHotkey = true
                    } label: {
                        Label("Add Shortcut", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedID = shortcutManager.selectedHotkeyID,
               let hotkey = shortcutManager.hotkeys.first(where: { $0.id == selectedID }) {
                HotkeyDetailView(hotkey: hotkey)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                    Text("Select a keyboard shortcut")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("or create a new one")
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $isAddingHotkey) {
            AddHotkeyView()
        }
        .sheet(item: $shortcutManager.editingHotkey) { hotkey in
            EditHotkeyView(hotkey: hotkey)
        }
        .onAppear {
            checkAccessibilityPermissions()
            startPermissionMonitoring()
            shortcutManager.requestAccessibilityPermissions()
        }
        .onDisappear {
            permissionCheckTimer?.invalidate()
        }
    }
    
    private func checkAccessibilityPermissions() {
        hasAccessibilityPermissions = shortcutManager.hasAccessibilityPermissions
    }
    
    private func startPermissionMonitoring() {
        // Check permission status every 2 seconds
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            checkAccessibilityPermissions()
        }
    }
}

#Preview {
    ContentView()
}
