//
//  SettingsView.swift
//  paylas
//

import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.showsCursorKey) private var showsCursor = true
    @AppStorage(AppSettings.hotkeyEnabledKey) private var hotkeyEnabled = true

    var body: some View {
        Form {
            Section("Aufnahme") {
                Toggle("Mauszeiger im Stream anzeigen", isOn: $showsCursor)
            }

            Section("Tastenkürzel") {
                Toggle("Globales Tastenkürzel aktivieren", isOn: $hotkeyEnabled)
                    .onChange(of: hotkeyEnabled) { _, enabled in
                        HotkeyManager.shared.setEnabled(enabled)
                    }
                Text("⌃⌥⇧2 öffnet den Section-Selector")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

#Preview {
    SettingsView()
}
