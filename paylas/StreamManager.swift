//
//  StreamManager.swift
//  paylas
//
//  Tracks the currently active section streams so the status bar menu can
//  list and stop them.
//

import AppKit

final class StreamSession {
    let id = UUID()
    let title: String
    private let captureManager: ScreenCaptureManager
    private let windowController: StreamWindowController

    init(title: String, captureManager: ScreenCaptureManager, windowController: StreamWindowController) {
        self.title = title
        self.captureManager = captureManager
        self.windowController = windowController
    }

    func stop() {
        captureManager.stop()
        windowController.close()
    }
}

final class StreamManager {
    private(set) var sessions: [StreamSession] = []

    func addSession(_ session: StreamSession) {
        sessions.append(session)
    }

    func removeSession(id: UUID) {
        sessions.removeAll { $0.id == id }
    }

    func stopSession(id: UUID) {
        sessions.first(where: { $0.id == id })?.stop()
    }

    func stopAll() {
        sessions.forEach { $0.stop() }
        sessions.removeAll()
    }
}
