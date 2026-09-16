//
//  AppDelegate.swift
//  paylas
//

import AppKit
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppSettings.registerDefaults()
        NSApp.setActivationPolicy(.accessory)

        statusBarController = StatusBarController()

        KeyboardShortcuts.onKeyUp(for: .sectionSelector) { [weak statusBarController] in
            statusBarController?.startSectionSelector()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
