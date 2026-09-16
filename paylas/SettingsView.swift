//
//  SettingsView.swift
//  paylas
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage(AppSettings.showsCursorKey) private var showsCursor = true

    var body: some View {
        Form {
            Section("Aufnahme") {
                Toggle("Mauszeiger im Stream anzeigen", isOn: $showsCursor)
            }

            Section("Tastenkürzel") {
                KeyboardShortcuts.Recorder("Section-Selector öffnen:", name: .sectionSelector)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

#Preview {
    SettingsView()
}
