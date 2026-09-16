//
//  paylasApp.swift
//  paylas
//
//  Created by Enis Erdem Ciftci on 15.09.26.
//

import SwiftUI

@main
struct paylasApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
