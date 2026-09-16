//
//  StreamController.swift
//  paylas
//
//  Orchestrates the single section stream: selection overlay, stream window,
//  capture and border. A new selection replaces the running stream and
//  reuses its window.
//

import AppKit
import KeyboardShortcuts
import Observation
import os

private let logger = Logger(subsystem: "enercif.paylas", category: "stream")

@Observable
final class StreamController {
    private var windowController: StreamWindowController?
    private var captureManager: ScreenCaptureManager?
    private var borderWindow: StreamBorderWindow?
    private var startTask: Task<Void, Never>?
    private let overlay = SectionSelectorOverlay()

    var isStreaming: Bool { windowController != nil }

    var isBlurred = false {
        didSet { windowController?.isBlurred = isBlurred }
    }

    init() {
        KeyboardShortcuts.onKeyUp(for: .sectionSelector) { [weak self] in
            self?.startSectionSelector()
        }
        KeyboardShortcuts.onKeyUp(for: .toggleBlur) { [weak self] in
            guard let self, self.isStreaming else { return }
            self.isBlurred.toggle()
        }
    }

    func startSectionSelector() {
        guard let screen = Self.screenUnderCursor() ?? NSScreen.main else { return }
        overlay.present(on: screen) { [weak self] rect in
            guard let self, let rect else { return }
            self.startStream(rect: rect, screen: screen)
        }
    }

    func stopStream() {
        windowController?.close()
        // close() normally tears down via onWindowClosed; call it directly in case the window never showed.
        tearDown()
    }

    private func startStream(rect: CGRect, screen: NSScreen) {
        // A newer selection wins; the older start stops its own stream when it notices.
        startTask?.cancel()
        startTask = Task { [weak self] in
            guard let self else { return }
            do {
                let filter = try await ScreenCaptureManager.contentFilter(for: screen)
                try Task.checkCancellation()

                let title = "Paylas – \(Int(rect.width))×\(Int(rect.height))"
                let windowController = self.windowController ?? StreamWindowController(title: title, contentSize: rect.size)
                windowController.window?.title = title
                windowController.window?.setContentSize(rect.size)
                windowController.isBlurred = self.isBlurred
                windowController.onToggleBlur = { [weak self] in
                    self?.isBlurred.toggle()
                }
                windowController.onWindowClosed = { [weak self] in
                    self?.tearDown()
                }
                self.windowController = windowController

                let captureManager = self.captureManager ?? ScreenCaptureManager(displayLayer: windowController.displayLayer)
                self.captureManager = captureManager
                try await captureManager.start(
                    filter: filter,
                    cropRect: rect.flipped(inContainerHeight: screen.frame.height),
                    scale: screen.backingScaleFactor
                )
                windowController.showWindow(nil)

                self.borderWindow?.close()
                let borderWindow = StreamBorderWindow(rect: rect, screen: screen)
                borderWindow.orderFrontRegardless()
                self.borderWindow = borderWindow
            } catch {
                guard !Task.isCancelled else { return }
                logger.error("Stream konnte nicht gestartet werden: \(error.localizedDescription, privacy: .public)")
                self.stopStream()
                self.presentCaptureError(error)
            }
        }
    }

    private func tearDown() {
        startTask?.cancel()
        captureManager?.stop()
        captureManager = nil
        windowController = nil
        isBlurred = false
        borderWindow?.close()
        borderWindow = nil
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
