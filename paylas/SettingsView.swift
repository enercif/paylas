//
//  SettingsView.swift
//  paylas
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage(AppSettings.showsCursorKey) private var showsCursor = AppSettings.showsCursorDefault
    @AppStorage(AppSettings.showsBorderKey) private var showsBorder = AppSettings.showsBorderDefault
    @AppStorage(AppSettings.borderColorKey) private var borderColor = AppSettings.borderColorDefault
    @AppStorage(AppSettings.excludedAppsKey) private var excludedApps = ""
    @State private var installedApps: [InstalledApp] = []

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

            Section("Im Stream ausblenden") {
                List(installedApps) { app in
                    Toggle(isOn: isExcluded(app)) {
                        Label {
                            Text(app.name)
                        } icon: {
                            Image(nsImage: app.icon)
                        }
                    }
                }
                .frame(height: 220)
            }

            Section("Tastenkürzel") {
                KeyboardShortcuts.Recorder("Bereichsauswahl öffnen:", name: .sectionSelector)
                KeyboardShortcuts.Recorder("Stream unscharf schalten:", name: .toggleBlur)
            }
        }
        .padding(20)
        .frame(width: 360)
        .task { installedApps = InstalledApp.all() }
    }

    private func isExcluded(_ app: InstalledApp) -> Binding<Bool> {
        Binding {
            excludedApps.split(separator: ",").contains(Substring(app.id))
        } set: { excluded in
            var ids = Set(excludedApps.split(separator: ",").map(String.init))
            if excluded { ids.insert(app.id) } else { ids.remove(app.id) }
            excludedApps = ids.sorted().joined(separator: ",")
        }
    }
}

private struct InstalledApp: Identifiable {
    let id: String // bundle identifier
    let name: String
    let icon: NSImage

    /// Apps in /Applications and /System/Applications, without Paylas itself (always hidden).
    static func all() -> [InstalledApp] {
        var apps: [String: InstalledApp] = [:]
        for directory in ["/Applications", "/System/Applications"] {
            let enumerator = FileManager.default.enumerator(
                at: URL(filePath: directory),
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
            while let url = enumerator?.nextObject() as? URL {
                guard url.pathExtension == "app",
                      let id = Bundle(url: url)?.bundleIdentifier,
                      id != Bundle.main.bundleIdentifier else { continue }
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                icon.size = NSSize(width: 16, height: 16)
                apps[id] = InstalledApp(id: id, name: FileManager.default.displayName(atPath: url.path), icon: icon)
            }
        }
        return apps.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

#Preview {
    SettingsView()
}
