//
//  HotkeyBinding.swift
//  HotkeysAndShortcuts
//
//  Data models for hotkey bindings and actions
//

import Foundation
import SwiftUI
import Carbon
import AppKit

// MARK: - Modifier Converter

/// Converts modifier keys between NSEvent and Carbon formats
enum ModifierConverter {
    /// Converts Carbon modifiers to symbol strings (⌘, ⌃, ⌥, ⇧)
    static func symbolsFromCarbon(_ modifiers: UInt32) -> [String] {
        var symbols: [String] = []
        if modifiers & UInt32(controlKey) != 0 { symbols.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { symbols.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { symbols.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { symbols.append("⌘") }
        return symbols
    }
    
    /// Converts NSEvent modifier flags to Carbon format
    static func carbonFromNSEvent(_ flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.option) { carbon |= UInt32(optionKey) }
        if flags.contains(.shift) { carbon |= UInt32(shiftKey) }
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        return carbon
    }
}

// MARK: - Hotkey Action

/// Action to perform when hotkey is triggered
enum HotkeyAction: Codable, Equatable {
    case shortcut(name: String)
    case windowManagement(position: WindowPosition)
    
    var displayName: String {
        switch self {
        case .shortcut(let name): return name
        case .windowManagement(let position): return position.displayName
        }
    }
    
    var icon: String {
        switch self {
        case .shortcut: return "arrow.triangle.turn.up.right.diamond.fill"
        case .windowManagement: return "rectangle.fill.on.rectangle.fill"
        }
    }
    
    /// UI color for action type
    var color: Color {
        switch self {
        case .shortcut: return .orange
        case .windowManagement: return .blue
        }
    }
    
    /// Type description for UI
    var typeTitle: String {
        switch self {
        case .shortcut: return "Run Shortcut"
        case .windowManagement: return "Window Management"
        }
    }
    
    /// Detailed action description
    var description: String {
        switch self {
        case .shortcut: return "Execute an Apple Shortcut"
        case .windowManagement(let position): return positionDescription(for: position)
        }
    }
    
    /// Test button label
    var testButtonTitle: String {
        switch self {
        case .shortcut: return "Run Now"
        case .windowManagement: return "Apply Now"
        }
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
}

// MARK: - Window Position

enum WindowPosition: String, Codable, CaseIterable {
    case leftHalf = "left_half"
    case rightHalf = "right_half"
    case topHalf = "top_half"
    case bottomHalf = "bottom_half"
    case fullScreen = "full_screen"
    case center = "center"
    case topLeft = "top_left"
    case topRight = "top_right"
    case bottomLeft = "bottom_left"
    case bottomRight = "bottom_right"
    case maximize = "maximize"
    case nextScreen = "next_screen"
    case previousScreen = "previous_screen"
    case minimize = "minimize"
    case hide = "hide"
    
    var displayName: String {
        switch self {
        case .leftHalf: return "Left Half"
        case .rightHalf: return "Right Half"
        case .topHalf: return "Top Half"
        case .bottomHalf: return "Bottom Half"
        case .fullScreen: return "Full Screen"
        case .center: return "Center"
        case .topLeft: return "Top Left Quarter"
        case .topRight: return "Top Right Quarter"
        case .bottomLeft: return "Bottom Left Quarter"
        case .bottomRight: return "Bottom Right Quarter"
        case .maximize: return "Maximize"
        case .nextScreen: return "Move to Next Screen"
        case .previousScreen: return "Move to Previous Screen"
        case .minimize: return "Minimize Window"
        case .hide: return "Hide Application"
        }
    }
    
    var systemImage: String {
        switch self {
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .fullScreen: return "arrow.up.left.and.arrow.down.right"
        case .center: return "square.dashed"
        case .topLeft: return "square.topthird.inset.filled"
        case .topRight: return "square.topthird.inset.filled"
        case .bottomLeft: return "square.bottomthird.inset.filled"
        case .bottomRight: return "square.bottomthird.inset.filled"
        case .maximize: return "arrow.up.backward.and.arrow.down.forward"
        case .nextScreen: return "arrow.right.to.line"
        case .previousScreen: return "arrow.left.to.line"
        case .minimize: return "minus.rectangle"
        case .hide: return "eye.slash"
        }
    }
}

// MARK: - Hotkey Binding Model

struct HotkeyBinding: Identifiable, Codable {
    let id: UUID
    var action: HotkeyAction
    var keyCode: UInt16
    var modifiers: UInt32
    var isEnabled: Bool
    
    // Legacy support for old shortcuts
    var shortcutName: String {
        get {
            switch action {
            case .shortcut(let name):
                return name
            case .windowManagement(let position):
                return position.displayName
            }
        }
        set {
            // This maintains backward compatibility
            action = .shortcut(name: newValue)
        }
    }
    
    init(id: UUID = UUID(), action: HotkeyAction, keyCode: UInt16, modifiers: UInt32, isEnabled: Bool = true) {
        self.id = id
        self.action = action
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }
    
    // Convenience initializer for shortcuts (backward compatibility)
    init(id: UUID = UUID(), shortcutName: String, keyCode: UInt16, modifiers: UInt32, isEnabled: Bool = true) {
        self.id = id
        self.action = .shortcut(name: shortcutName)
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }
    
    // Convenience initializer for window management
    init(id: UUID = UUID(), windowPosition: WindowPosition, keyCode: UInt16, modifiers: UInt32, isEnabled: Bool = true) {
        self.id = id
        self.action = .windowManagement(position: windowPosition)
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
    }
    
    /// Human-readable key combination (e.g., "⌘⇧A")
    var keyComboDescription: String {
        var parts = ModifierConverter.symbolsFromCarbon(modifiers)
        parts.append(KeyCodeMapper.keyName(for: keyCode) ?? "Key \(keyCode)")
        return parts.joined()
    }
}

// MARK: - Key Code Mapper

enum KeyCodeMapper {
    static func keyName(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "↩︎"  // Return
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "⇥"  // Tab
        case 49: return "␣"  // Space
        case 50: return "`"
        case 51: return "⌫"  // Delete
        case 53: return "⎋"  // Escape
        case 64: return "F17"
        case 65: return "."  // Keypad Decimal
        case 67: return "*"  // Keypad Multiply
        case 69: return "+"  // Keypad Plus
        case 71: return "⌧"  // Keypad Clear
        case 75: return "/"  // Keypad Divide
        case 76: return "⌅"  // Keypad Enter
        case 78: return "-"  // Keypad Minus
        case 79: return "F18"
        case 80: return "F19"
        case 81: return "="  // Keypad Equals
        case 82: return "0"  // Keypad 0
        case 83: return "1"  // Keypad 1
        case 84: return "2"  // Keypad 2
        case 85: return "3"  // Keypad 3
        case 86: return "4"  // Keypad 4
        case 87: return "5"  // Keypad 5
        case 88: return "6"  // Keypad 6
        case 89: return "7"  // Keypad 7
        case 91: return "8"  // Keypad 8
        case 92: return "9"  // Keypad 9
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 105: return "F13"
        case 106: return "F16"
        case 107: return "F14"
        case 109: return "F10"
        case 111: return "F12"
        case 113: return "F15"
        case 114: return "Help"
        case 115: return "Home"
        case 116: return "⇞"  // Page Up
        case 117: return "⌦"  // Forward Delete
        case 118: return "F4"
        case 119: return "End"
        case 120: return "F2"
        case 121: return "⇟"  // Page Down
        case 122: return "F1"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return nil
        }
    }
}
