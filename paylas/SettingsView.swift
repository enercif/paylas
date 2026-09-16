//
//  SettingsView.swift
//  paylas
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage(AppSettings.showsCursorKey) private var showsCursor = true
    @AppStorage(AppSettings.showsBorderKey) private var showsBorder = true
    @AppStorage(AppSettings.borderColorKey) private var borderColor = Color.blue

    var body: some View {
        Form {
            Section("Aufnahme") {
                Toggle("Mauszeiger im Stream anzeigen", isOn: $showsCursor)
            }

            Section("Markierung") {
                Toggle("Stream-Bereich gestrichelt umranden", isOn: $showsBorder)
                ColorPicker("Farbe der Umrandung", selection: $borderColor, supportsOpacity: false)
                    .disabled(!showsBorder)
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
