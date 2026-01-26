//
//  AboutSettingsView.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import SwiftUI

/// About tab in settings showing app information
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard.badge.ellipsis")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Hotkeys & Shortcuts")
                .font(.title)
            
            Text("Version 1.0")
                .foregroundStyle(.secondary)
            
            Text("Create custom keyboard shortcuts that run your Apple Shortcuts with priority over other apps.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding()
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    AboutSettingsView()
        .frame(width: 500, height: 300)
}
