//
//  StatusBarController.swift
//  paylas
//
//  Owns the NSStatusItem, builds its menu on demand, and orchestrates
//  starting/stopping section streams.
//

import AppKit
import SwiftUI

final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let streamManager = StreamManager()
    private let overlay = SectionSelectorOverlay()
    private let settingsScene = NSHostingSceneRepresentation {
        Settings {
            SettingsView()
        }
    }

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "rectangle.on.rectangle", accessibilityDescription: "Paylas")
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    func startSectionSelector() {
        guard let screen = Self.screenUnderCursor() ?? NSScreen.main else { return }
        overlay.present(on: screen) { [weak self] rect in
            guard let self, let rect else { return }
            self.startStream(rect: rect, screen: screen)
        }
    }

    private func startStream(rect: CGRect, screen: NSScreen) {
        Task { [weak self] in
            guard let self else { return }
            do {
                let display = try await ScreenCaptureManager.matchingDisplay(for: screen)
                let topLeftOriginRect = CGRect(
                    x: rect.minX,
                    y: screen.frame.height - rect.maxY,
                    width: rect.width,
                    height: rect.height
                )

                let windowController = StreamWindowController(
                    title: "Paylas – \(Int(rect.width))×\(Int(rect.height))",
                    contentSize: rect.size
                )
                let captureManager = ScreenCaptureManager(displayLayer: windowController.displayLayer)
                try await captureManager.start(display: display, cropRect: topLeftOriginRect, scale: screen.backingScaleFactor)

                let session = StreamSession(
                    title: windowController.window?.title ?? "Stream",
                    captureManager: captureManager,
                    windowController: windowController
                )
                windowController.onWindowClosed = { [weak self] in
                    self?.streamManager.removeSession(id: session.id)
                }
                self.streamManager.addSession(session)
                windowController.showWindow(nil)
            } catch {
                NSLog("Paylas: Stream konnte nicht gestartet werden: \(error.localizedDescription)")
                self.presentCaptureError(error)
            }
        }
    }

    private func presentCaptureError(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "Bildschirmfreigabe fehlgeschlagen"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }

    private static func screenUnderCursor() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
    }
}

extension StatusBarController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let selectItem = NSMenuItem(title: "Select Section", action: #selector(selectSection), keyEquivalent: "")
        selectItem.target = self
        menu.addItem(selectItem)

        if !streamManager.sessions.isEmpty {
            menu.addItem(.separator())
            let headerItem = NSMenuItem(title: "Aktive Streams", action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            menu.addItem(headerItem)

            for session in streamManager.sessions {
                let item = NSMenuItem(title: session.title, action: nil, keyEquivalent: "")
                let submenu = NSMenu()
                let stopItem = NSMenuItem(title: "Beenden", action: #selector(stopSession(_:)), keyEquivalent: "")
                stopItem.target = self
                stopItem.representedObject = session.id
                submenu.addItem(stopItem)
                item.submenu = submenu
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func selectSection() {
        startSectionSelector()
    }

    @objc private func stopSession(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        streamManager.stopSession(id: id)
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        settingsScene.environment.openSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
