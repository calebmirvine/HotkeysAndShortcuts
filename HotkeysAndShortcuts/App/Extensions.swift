//
//  Extensions.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import Foundation
import SwiftUI

// MARK: - View Extensions

extension View {
    /// Applies a standard card style
    func cardStyle() -> some View {
        self
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Color Extensions

extension Color {
    static let accentBlue = Color.blue
    static let accentGreen = Color.green
    static let accentOrange = Color.orange
    static let accentRed = Color.red
}

// MARK: - Hotkey Binding Extensions

extension HotkeyBinding {
    /// Returns a user-friendly description of the hotkey
    var fullDescription: String {
        "\(keyComboDescription) → \(shortcutName)"
    }
    
    /// Validates if the hotkey configuration is valid
    var isValid: Bool {
        !shortcutName.isEmpty && keyCode != 0 && modifiers != 0
    }
}

// MARK: - String Extensions

extension String {
    /// Truncates string to a maximum length
    func truncated(to length: Int, trailing: String = "...") -> String {
        if self.count > length {
            return String(self.prefix(length)) + trailing
        }
        return self
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hotkeyTriggered = Notification.Name("hotkeyTriggered")
    static let shortcutCompleted = Notification.Name("shortcutCompleted")
    static let shortcutFailed = Notification.Name("shortcutFailed")
}
