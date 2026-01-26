//
//  KeyRecorder.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import Foundation
import SwiftUI
import Carbon
import Cocoa

// MARK: - Key Recorder

@Observable
class KeyRecorder {
    var keyCode: UInt16 = 0
    var modifiers: UInt32 = 0
    var isRecording = false
    
    private var eventMonitor: Any?
    
    var keyComboDescription: String {
        guard hasValidKeyCombination else { return "" }
        
        var parts: [String] = []
        
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("⌃")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("⇧")
        }
        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("⌘")
        }
        
        if let keyName = KeyCodeMapper.keyName(for: keyCode) {
            parts.append(keyName)
        }
        
        return parts.joined(separator: "")
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
            
            // Only capture key down events with modifiers
            if event.type == .keyDown {
                let keyCode = UInt16(event.keyCode)
                
                // Convert NSEvent modifiers to Carbon modifiers
                var carbonModifiers: UInt32 = 0
                
                if event.modifierFlags.contains(.control) {
                    carbonModifiers |= UInt32(controlKey)
                }
                if event.modifierFlags.contains(.option) {
                    carbonModifiers |= UInt32(optionKey)
                }
                if event.modifierFlags.contains(.shift) {
                    carbonModifiers |= UInt32(shiftKey)
                }
                if event.modifierFlags.contains(.command) {
                    carbonModifiers |= UInt32(cmdKey)
                }
                
                // Require at least one modifier
                if carbonModifiers != 0 {
                    self.keyCode = keyCode
                    self.modifiers = carbonModifiers
                    self.stopRecording()
                    return nil // Consume the event
                }
            }
            
            return nil // Consume all events while recording
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
