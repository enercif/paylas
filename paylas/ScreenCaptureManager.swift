//
//  ScreenCaptureManager.swift
//  paylas
//
//  Captures a cropped region of a single display via ScreenCaptureKit and
//  feeds the resulting sample buffers straight into an AVSampleBufferDisplayLayer
//  owned by a StreamWindow, so the mirrored section updates live.
//

import AppKit
import AVFoundation
import ScreenCaptureKit

enum ScreenCaptureError: LocalizedError {
    case displayNotFound

    var errorDescription: String? {
        switch self {
        case .displayNotFound:
            return "Der ausgewählte Bildschirm konnte nicht für die Aufnahme gefunden werden."
        }
    }
}

final class ScreenCaptureManager: NSObject {
    private let displayLayer: AVSampleBufferDisplayLayer
    private let captureQueue = DispatchQueue(label: "com.paylas.capture")
    private var stream: SCStream?

    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
    }

    /// Finds the SCDisplay that corresponds to a given NSScreen by matching CGDirectDisplayID.
    static func matchingDisplay(for screen: NSScreen) async throws -> SCDisplay {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        let screenNumber = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
        guard let match = content.displays.first(where: { $0.displayID == screenNumber }) else {
            throw ScreenCaptureError.displayNotFound
        }
        return match
    }

    /// - Parameter cropRect: The capture region in points, in the display's own
    ///   top-left-origin coordinate space (not the global desktop space).
    func start(display: SCDisplay, cropRect: CGRect, scale: CGFloat) async throws {
        let filter = SCContentFilter(display: display, excludingWindows: [])

        let configuration = SCStreamConfiguration()
        configuration.sourceRect = cropRect
        configuration.width = max(2, Int(cropRect.width * scale))
        configuration.height = max(2, Int(cropRect.height * scale))
        configuration.showsCursor = UserDefaults.standard.bool(forKey: AppSettings.showsCursorKey)
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.queueDepth = 5
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)

        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: captureQueue)
        try await stream.startCapture()
        self.stream = stream
    }

    func stop() {
        guard let stream else { return }
        self.stream = nil
        Task { try? await stream.stopCapture() }
    }
}

extension ScreenCaptureManager: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid else { return }

        DispatchQueue.main.async { [displayLayer] in
            let renderer = displayLayer.sampleBufferRenderer
            if renderer.status == .failed {
                renderer.flush()
            }
            renderer.enqueue(sampleBuffer)
        }
    }
}

extension ScreenCaptureManager: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        NSLog("Paylas: Stream wurde unerwartet beendet: \(error.localizedDescription)")
    }
}
