//
//  KeyRecorder.swift
//  HotkeysAndShortcuts
//
//  Records keyboard shortcuts while temporarily pausing global hotkey monitoring
//

import Foundation
import SwiftUI
import Carbon
import Cocoa

/// Records user keyboard input for hotkey assignment
@Observable
class KeyRecorder {
    var keyCode: UInt16 = 0
    var modifiers: UInt32 = 0
    var isRecording = false
    
    private var eventMonitor: Any?
    
    /// Human-readable key combination (e.g., "⌘⇧A")
    var keyComboDescription: String {
        guard hasValidKeyCombination else { return "" }
        var parts = ModifierConverter.symbolsFromCarbon(modifiers)
        if let keyName = KeyCodeMapper.keyName(for: keyCode) {
            parts.append(keyName)
        }
        return parts.joined()
    }
    
    var hasValidKeyCombination: Bool {
        keyCode != 0 && modifiers != 0
    }
    
    func startRecording() {
        isRecording = true
        
        // CRITICAL: Pause global event monitoring so we can capture keys locally
        Task { @MainActor in
            ShortcutManager.shared.pauseHotkeyMonitoring()
        }
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { [weak self] event in
            guard let self = self else { return event }
            
            // Handle Escape to cancel
            if event.keyCode == 53 { // Escape key
                self.stopRecording()
                return nil
            }
            
            // Capture keyDown events with modifiers
            if event.type == .keyDown {
                let carbonMods = ModifierConverter.carbonFromNSEvent(event.modifierFlags)
                
                // Debug logging
                print("🎙️ Recording keyDown: keyCode=\(event.keyCode), carbonMods=\(carbonMods)")
                print("   Raw modifierFlags: \(event.modifierFlags.rawValue)")
                
                // Require at least one modifier key
                if carbonMods != 0 {
                    self.keyCode = UInt16(event.keyCode)
                    self.modifiers = carbonMods
                    let modSymbols = ModifierConverter.symbolsFromCarbon(carbonMods).joined()
                    let keyName = KeyCodeMapper.keyName(for: UInt16(event.keyCode)) ?? "\(event.keyCode)"
                    print("✅ Recorded: \(modSymbols)\(keyName) (keyCode: \(event.keyCode), mods: \(carbonMods))")
                    self.stopRecording()
                    return nil
                }
                print("❌ Rejected: carbonMods is 0")
                return nil // Consume keyDown without modifiers
            }
            
            // Allow flagsChanged events to pass through
            // This is important for proper modifier key handling
            return event
        }
    }
    
    func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        // Resume global event monitoring
        Task { @MainActor in
            ShortcutManager.shared.resumeHotkeyMonitoring()
        }
    }
    
    func clear() {
        // Make sure to stop recording if it's still active
        if isRecording {
            stopRecording()
        }
        keyCode = 0
        modifiers = 0
    }
}
