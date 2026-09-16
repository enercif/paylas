//
//  AppSettings.swift
//  paylas
//

import AppKit
import KeyboardShortcuts

enum AppSettings {
    static let showsCursorKey = "paylas.showsCursor"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            showsCursorKey: true
        ])
    }
}

extension KeyboardShortcuts.Name {
    static let sectionSelector = Self("sectionSelector", default: .init(.two, modifiers: [.control, .option, .shift]))
}
