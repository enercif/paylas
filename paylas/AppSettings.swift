//
//  AppSettings.swift
//  paylas
//

import Foundation

enum AppSettings {
    static let showsCursorKey = "paylas.showsCursor"
    static let hotkeyEnabledKey = "paylas.hotkeyEnabled"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            showsCursorKey: true,
            hotkeyEnabledKey: true
        ])
    }
}
