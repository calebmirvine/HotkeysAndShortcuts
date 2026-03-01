//
//  ShortcutManager.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import Foundation
import Carbon
import Cocoa
import AppIntents
import SwiftUI
import Combine

// MARK: - Shortcut Manager

@MainActor
class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    @Published var hotkeys: [HotkeyBinding] = []
    @Published var selectedHotkeyID: UUID?
    @Published var editingHotkey: HotkeyBinding?
    
    private var eventMonitor: EventMonitor?
    private var registeredHotkeys: [UUID: EventHotKeyRef] = [:]
    private let storage = HotkeyStorage()
    
    private init() {
        loadHotkeys()
        
        // Request permissions if not granted, then setup monitor
        if !hasAccessibilityPermissions {
            requestAccessibilityPermissions()
        } else {
            setupEventMonitor()
        }
    }
    
    // MARK: - Hotkey Management
    
    func addHotkey(action: HotkeyAction, keyCode: UInt16, modifiers: UInt32) {
        let hotkey = HotkeyBinding(
            action: action,
            keyCode: keyCode,
            modifiers: modifiers
        )
        hotkeys.append(hotkey)
        saveHotkeys()
        registerHotkey(hotkey)
    }
    
    func deleteHotkey(_ hotkey: HotkeyBinding) {
        unregisterHotkey(hotkey)
        hotkeys.removeAll { $0.id == hotkey.id }
        if selectedHotkeyID == hotkey.id {
            selectedHotkeyID = nil
        }
        saveHotkeys()
    }
    
    func updateHotkey(_ hotkey: HotkeyBinding, keyCode: UInt16, modifiers: UInt32) {
        guard let index = hotkeys.firstIndex(where: { $0.id == hotkey.id }) else { return }
        
        unregisterHotkey(hotkey)
        
        hotkeys[index].keyCode = keyCode
        hotkeys[index].modifiers = modifiers
        
        saveHotkeys()
        registerHotkey(hotkeys[index])
    }
    
    func toggleHotkey(_ hotkey: HotkeyBinding, enabled: Bool) {
        guard let index = hotkeys.firstIndex(where: { $0.id == hotkey.id }) else { return }
        
        if enabled {
            registerHotkey(hotkey)
        } else {
            unregisterHotkey(hotkey)
        }
        
        hotkeys[index].isEnabled = enabled
        saveHotkeys()
    }
    
    func editHotkey(_ hotkey: HotkeyBinding) {
        editingHotkey = hotkey
    }
    
    // MARK: - Event Monitor Control
    
    /// Temporarily pause hotkey monitoring (used when recording new key combinations)
    func pauseHotkeyMonitoring() {
        print("⏸️ Pausing hotkey monitoring for key recording")
        eventMonitor?.pauseMonitoring()
    }
    
    /// Resume hotkey monitoring after recording
    func resumeHotkeyMonitoring() {
        print("▶️ Resuming hotkey monitoring")
        eventMonitor?.resumeMonitoring()
    }
    
    // MARK: - Event Monitoring
    
    private func setupEventMonitor() {
        // Clean up existing event monitor if any
        if eventMonitor != nil {
            print("Cleaning up existing event monitor...")
            eventMonitor = nil
        }
        
        // Check if we have accessibility permissions
        guard hasAccessibilityPermissions else {
            print("⚠️ Cannot setup event monitor: Accessibility permissions not granted")
            return
        }
        
        print("Setting up event monitor with accessibility permissions...")
        eventMonitor = EventMonitor()
        eventMonitor?.onHotkeyPressed = { [weak self] hotkeyID in
            guard let self = self else { return }
            Task { @MainActor in
                if let hotkey = self.hotkeys.first(where: { $0.id == hotkeyID }) {
                    await self.executeHotkeyAction(hotkey)
                }
            }
        }
        
        // Register all enabled hotkeys
        for hotkey in hotkeys where hotkey.isEnabled {
            registerHotkey(hotkey)
        }
        
        if eventMonitor == nil {
            print("❌ WARNING: Event monitor is nil after setup!")
        } else {
            print("✅ Event monitor setup complete. Registered \(hotkeys.filter(\.isEnabled).count) hotkeys")
        }
    }
    
    private func executeHotkeyAction(_ hotkey: HotkeyBinding) async {
        switch hotkey.action {
        case .shortcut(let name):
            await runShortcut(named: name)
            
        case .windowManagement(let position):
            executeWindowManagement(position)
        }
    }
    
    private func executeWindowManagement(_ position: WindowPosition) {
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
        
        if success {
            showNotification(title: "Window Action", message: position.displayName)
        } else {
            showNotification(title: "Action Failed", message: "Could not perform \(position.displayName)")
        }
    }
    
    private func registerHotkey(_ hotkey: HotkeyBinding) {
        guard hotkey.isEnabled else { return }
        
        eventMonitor?.registerHotkey(
            id: hotkey.id,
            keyCode: hotkey.keyCode,
            modifiers: hotkey.modifiers
        )
    }
    
    private func unregisterHotkey(_ hotkey: HotkeyBinding) {
        eventMonitor?.unregisterHotkey(id: hotkey.id)
    }
    
    // MARK: - Shortcuts Integration
    
    func fetchAvailableShortcuts() async -> [String] {
        do {
            // Run AppleScript to get shortcuts from the Shortcuts app
            let script = """
            tell application "Shortcuts Events"
                get name of every shortcut
            end tell
            """
            
            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                let output = scriptObject.executeAndReturnError(&error)
                
                if let error = error {
                    print("AppleScript error: \(error)")
                    // Fallback: return some example shortcuts
                    return await fetchShortcutsViaShell()
                }
                
                if let listDescriptor = output.coerce(toDescriptorType: typeAEList) {
                    var shortcuts: [String] = []
                    for i in 1...listDescriptor.numberOfItems {
                        if let item = listDescriptor.atIndex(i)?.stringValue {
                            shortcuts.append(item)
                        }
                    }
                    return shortcuts.sorted()
                }
            }
            
            // Fallback method
            return await fetchShortcutsViaShell()
        }
    }
    
    private func fetchShortcutsViaShell() async -> [String] {
        // Use the shortcuts CLI to list shortcuts
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        task.arguments = ["list"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let shortcuts = output.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                return shortcuts.sorted()
            }
        } catch {
            print("Error fetching shortcuts: \(error)")
        }
        
        return []
    }
    
    func runShortcut(named name: String) async {
        // Show a notification that we're running the shortcut
        showNotification(title: "Running Shortcut", message: name)
        
        // Use the shortcuts CLI to run the shortcut
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        task.arguments = ["run", name]
        
        do {
            try task.run()
            
            // Wait for completion in background
            Task.detached {
                task.waitUntilExit()
                
                await MainActor.run {
                    if task.terminationStatus == 0 {
                        self.showNotification(title: "Shortcut Completed", message: name)
                    } else {
                        self.showNotification(title: "Shortcut Failed", message: "\(name) (exit code: \(task.terminationStatus))")
                    }
                }
            }
        } catch {
            print("Error running shortcut: \(error)")
            showNotification(title: "Error", message: "Failed to run \(name)")
        }
    }
    
    private func showNotification(title: String, message: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = message
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    // MARK: - Accessibility Permissions
    
    var hasAccessibilityPermissions: Bool {
        return AXIsProcessTrusted()
    }
    
    func requestAccessibilityPermissions(showSuccessAlert: Bool = false) {
        Task { @MainActor in
            // Check if we already have permissions
            if hasAccessibilityPermissions {
                print("✅ Accessibility permissions already granted")
                
                if showSuccessAlert {
                    let alert = NSAlert()
                    alert.messageText = "Accessibility Permissions Granted"
                    alert.informativeText = "Hotkeys & Shortcuts has the necessary permissions to capture keyboard shortcuts."
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
                return
            }
            
            print("❌ Accessibility permissions not granted, requesting...")
            
            // Use macOS native prompt - kAXTrustedCheckOptionPrompt triggers system alert
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
            
            // Start polling to detect when permissions are granted
            startPermissionPolling()
        }
    }
    
    private func startPermissionPolling() {
        // Poll every second to check if permissions were granted
        Task {
            for _ in 0..<30 { // Poll for up to 30 seconds
                try? await Task.sleep(for: .seconds(1))
                
                if hasAccessibilityPermissions {
                    print("✅ Accessibility permissions granted! Restarting event monitoring...")
                    await MainActor.run {
                        // Restart event monitoring now that we have permissions
                        setupEventMonitor()
                    }
                    break
                }
            }
        }
    }
    
    // MARK: - Persistence
    
    private func loadHotkeys() {
        hotkeys = storage.load()
        print("📋 Loaded \(hotkeys.count) hotkeys from storage")
        for hotkey in hotkeys where hotkey.isEnabled {
            let modSymbols = ModifierConverter.symbolsFromCarbon(hotkey.modifiers).joined()
            let keyName = KeyCodeMapper.keyName(for: hotkey.keyCode) ?? "\(hotkey.keyCode)"
            print("   - \(modSymbols)\(keyName) → \(hotkey.action.displayName)")
        }
    }
    
    private func saveHotkeys() {
        storage.save(hotkeys)
    }
}

// MARK: - Event Monitor

class EventMonitor {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    var onHotkeyPressed: ((UUID) -> Void)?
    
    private var hotkeyRegistry: [HotkeySignature: UUID] = [:]
    private var isPaused = false
    
    struct HotkeySignature: Hashable {
        let keyCode: UInt16
        let modifiers: UInt32
    }
    
    init() {
        setupEventTap()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupEventTap() {
        // First check if we have accessibility permissions
        guard AXIsProcessTrusted() else {
            print("⚠️ EventMonitor: Cannot create event tap without accessibility permissions")
            return
        }
        
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { proxy, type, event, refcon in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let monitor = Unmanaged<EventMonitor>.fromOpaque(refcon).takeUnretainedValue()
                return monitor.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("❌ Failed to create event tap - this usually means accessibility permissions are not granted")
            return
        }
        
        print("✅ Event tap created successfully")
        self.eventTap = eventTap
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        self.runLoopSource = runLoopSource
        print("✅ Event tap enabled and added to run loop")
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .keyDown {
            let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
            let flags = event.flags
            
            // Convert CGEventFlags to Carbon modifiers (strip device-dependent flags)
            var modifiers: UInt32 = 0
            if flags.contains(.maskControl) {
                modifiers |= UInt32(controlKey)
            }
            if flags.contains(.maskAlternate) {
                modifiers |= UInt32(optionKey)
            }
            if flags.contains(.maskShift) {
                modifiers |= UInt32(shiftKey)
            }
            if flags.contains(.maskCommand) {
                modifiers |= UInt32(cmdKey)
            }
            
            // Mask to only modifier keys (remove device-dependent flags)
            let deviceIndependentMask: UInt32 = UInt32(controlKey) | UInt32(optionKey) | UInt32(shiftKey) | UInt32(cmdKey)
            modifiers &= deviceIndependentMask
            
            let signature = HotkeySignature(keyCode: keyCode, modifiers: modifiers)
            
            if let hotkeyID = hotkeyRegistry[signature] {
                // Prevent the event from propagating to other apps
                onHotkeyPressed?(hotkeyID)
                return nil // Block the event
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    func registerHotkey(id: UUID, keyCode: UInt16, modifiers: UInt32) {
        let signature = HotkeySignature(keyCode: keyCode, modifiers: modifiers)
        let modSymbols = ModifierConverter.symbolsFromCarbon(modifiers).joined()
        let keyName = KeyCodeMapper.keyName(for: keyCode) ?? "\(keyCode)"
        print("📝 Registering hotkey: \(modSymbols)\(keyName) (keyCode: \(keyCode), mods: \(modifiers)) for ID: \(id)")
        
        // Check if this signature is already registered
        if let existingID = hotkeyRegistry[signature], existingID != id {
            print("⚠️ Warning: Hotkey signature \(signature) is already registered to \(existingID)")
        }
        
        hotkeyRegistry[signature] = id
    }
    
    func unregisterHotkey(id: UUID) {
        hotkeyRegistry = hotkeyRegistry.filter { $0.value != id }
        print("Unregistered hotkey: \(id)")
    }
    
    /// Temporarily disable the event tap (e.g., while recording new hotkeys)
    func pauseMonitoring() {
        guard let eventTap = eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: false)
        print("⏸️ Event monitoring paused")
    }
    
    /// Re-enable the event tap after pausing
    func resumeMonitoring() {
        guard let eventTap = eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: true)
        print("▶️ Event monitoring resumed")
    }
    
    private func cleanup() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
}

// MARK: - Storage

class HotkeyStorage {
    private let storageKey = "savedHotkeys"
    
    func save(_ hotkeys: [HotkeyBinding]) {
        if let encoded = try? JSONEncoder().encode(hotkeys) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func load() -> [HotkeyBinding] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([HotkeyBinding].self, from: data) else {
            return []
        }
        return decoded
    }
}
