//
//  HotkeyRow.swift
//  HotkeysAndShortcuts
//
//  List row view for a hotkey binding
//

import SwiftUI

/// Compact row displaying hotkey information in list
struct HotkeyRow: View {
    let hotkey: HotkeyBinding
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: hotkey.action.icon)
                .font(.body)
                .foregroundStyle(hotkey.action.color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(hotkey.action.displayName)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(hotkey.keyComboDescription)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 4)
            
            Image(systemName: hotkey.isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(hotkey.isEnabled ? .green : .secondary)
                .imageScale(.small)
                .frame(width: 16)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
    }
}
