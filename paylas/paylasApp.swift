//
//  paylasApp.swift
//  paylas
//
//  Created by Enis Erdem Ciftci on 15.09.26.
//

import AppKit
import SwiftUI

@main
struct paylasApp: App {
    @State private var streamController = StreamController()

    var body: some Scene {
        MenuBarExtra("Paylas", systemImage: "rectangle.on.rectangle") {
            MenuContent(streamController: streamController)
        }

        Settings {
            SettingsView()
        }
    }
}

private struct MenuContent: View {
    let streamController: StreamController
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("Bereich auswählen") {
            streamController.startSectionSelector()
        }

        if streamController.isStreaming {
            Button("Stream beenden") {
                streamController.stopStream()
            }
        }

        Divider()

        Button("Einstellungen…") {
            // Menu bar apps are not active by default, so the window would open behind others.
            NSApp.activate()
            openSettings()
        }
        .keyboardShortcut(",")

        Divider()

        Button("Beenden") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
