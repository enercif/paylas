//
//  SettingsView.swift
//  paylas
//

import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @State private var pane: Pane? = .general

    var body: some View {
        NavigationSplitView {
            List(Pane.allCases, selection: $pane) { pane in
                Label {
                    Text(pane.title)
                } icon: {
                    Image(systemName: pane.symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(pane.color.gradient, in: .rect(cornerRadius: 5))
                }
            }
            .navigationSplitViewColumnWidth(200)
            .toolbar(removing: .sidebarToggle)
        } detail: {
            let pane = pane ?? .general
            Group {
                switch pane {
                case .general: GeneralPane()
                case .hiddenApps: HiddenAppsPane()
                case .shortcuts: ShortcutsPane()
                }
            }
            .formStyle(.grouped)
            .navigationTitle(pane.title)
        }
        .frame(width: 680, height: 460)
    }
}

private enum Pane: CaseIterable, Identifiable {
    case general, hiddenApps, shortcuts

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "Allgemein"
        case .hiddenApps: "Im Stream ausblenden"
        case .shortcuts: "Tastenkürzel"
        }
    }

    var symbol: String {
        switch self {
        case .general: "gearshape"
        case .hiddenApps: "eye.slash"
        case .shortcuts: "keyboard"
        }
    }

    var color: Color {
        switch self {
        case .general: .gray
        case .hiddenApps: .blue
        case .shortcuts: .orange
        }
    }
}

private struct GeneralPane: View {
    @AppStorage(AppSettings.showsCursorKey) private var showsCursor = AppSettings.showsCursorDefault
    @AppStorage(AppSettings.showsBorderKey) private var showsBorder = AppSettings.showsBorderDefault
    @AppStorage(AppSettings.borderColorKey) private var borderColor = AppSettings.borderColorDefault

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
        }
    }
}

private struct HiddenAppsPane: View {
    @AppStorage(AppSettings.excludedAppsKey) private var excludedApps = ""
    @State private var installedApps: [InstalledApp] = []

    var body: some View {
        Form {
            Section {
                ForEach(installedApps) { app in
                    Toggle(isOn: isExcluded(app)) {
                        Label {
                            Text(app.name)
                        } icon: {
                            Image(nsImage: app.icon)
                        }
                    }
                }
            } footer: {
                Text("Fenster der ausgewählten Apps sind im Stream nicht sichtbar.")
                    .foregroundStyle(.secondary)
            }
        }
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

private struct ShortcutsPane: View {
    var body: some View {
        Form {
            Section {
                LabeledContent("Bereichsauswahl öffnen") {
                    KeyboardShortcuts.Recorder(for: .sectionSelector)
                }
                LabeledContent("Stream unscharf schalten") {
                    KeyboardShortcuts.Recorder(for: .toggleBlur)
                }
            }
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
