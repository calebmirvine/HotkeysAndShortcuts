//
//  HotkeyRow.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import SwiftUI

struct HotkeyRow: View {
    let hotkey: HotkeyBinding
    
    var body: some View {
        HStack(spacing: 12) {
            // Action type icon
            Image(systemName: hotkey.action.icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 30, height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(hotkey.shortcutName)
                    .font(.headline)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(hotkey.keyComboDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 8)
            
            if hotkey.isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .imageScale(.medium)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.secondary)
                    .imageScale(.medium)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var iconColor: Color {
        switch hotkey.action {
        case .shortcut:
            return .orange
        case .windowManagement:
            return .blue
        }
    }
}
