//
//  AppDelegate.swift
//  paylas
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppSettings.registerDefaults()
        NSApp.setActivationPolicy(.accessory)

        let controller = StatusBarController()
        statusBarController = controller

        HotkeyManager.shared.start { [weak controller] in
            controller?.startSectionSelector()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
