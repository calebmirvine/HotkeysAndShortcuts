//
//  SettingsView.swift
//  HotkeysAndShortcuts
//
//  Created by Caleb on 2026-01-25.
//

import SwiftUI

/// Main settings window with tabs
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
            
            UpdateSettingsView()
                .tabItem {
                    Label("Updates", systemImage: "arrow.down.circle")
                }
            
            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 300)
    }
}

#Preview {
    SettingsView()
}
