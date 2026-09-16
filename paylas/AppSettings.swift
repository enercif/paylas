//
//  AppSettings.swift
//  paylas
//

import AppKit
import SwiftUI
import KeyboardShortcuts

enum AppSettings {
    static let showsCursorKey = "paylas.showsCursor"
    static let showsCursorDefault = true

    static let showsBorderKey = "paylas.showsBorder"
    static let showsBorderDefault = true

    static let borderColorKey = "paylas.borderColor"
    static let borderColorDefault = Color.blue

    /// Comma-separated bundle identifiers of apps hidden from the stream.
    static let excludedAppsKey = "paylas.excludedApps"

    static var excludedAppIDs: Set<String> {
        Set((UserDefaults.standard.string(forKey: excludedAppsKey) ?? "").split(separator: ",").map(String.init))
    }
}

/// Lets @AppStorage persist a Color as "r,g,b,a" (sRGB).
extension Color: @retroactive RawRepresentable {
    nonisolated public init?(rawValue: String) {
        let components = rawValue.split(separator: ",").compactMap { Double($0) }
        guard components.count == 4 else { return nil }
        self.init(.sRGB, red: components[0], green: components[1], blue: components[2], opacity: components[3])
    }

    nonisolated public var rawValue: String {
        guard let color = NSColor(self).usingColorSpace(.sRGB) else { return "" }
        return "\(color.redComponent),\(color.greenComponent),\(color.blueComponent),\(color.alphaComponent)"
    }
}

extension KeyboardShortcuts.Name {
    static let sectionSelector = Self("sectionSelector", initial: .init(.two, modifiers: [.control, .option, .shift]))
}
