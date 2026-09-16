//
//  ScreenCaptureManager.swift
//  paylas
//
//  Captures a cropped region of a single display via ScreenCaptureKit and
//  feeds the resulting sample buffers straight into the AVSampleBufferDisplayLayer
//  owned by a StreamWindow, so the mirrored section updates live.
//

import AppKit
import AVFoundation
import ScreenCaptureKit
import os

private nonisolated let logger = Logger(subsystem: "enercif.paylas", category: "capture")

enum ScreenCaptureError: LocalizedError {
    case displayNotFound

    var errorDescription: String? {
        switch self {
        case .displayNotFound:
            return "Der ausgewählte Bildschirm konnte nicht für die Aufnahme gefunden werden."
        }
    }
}

/// One manager per stream window: `start` replaces a running stream, so the
/// display layer stays attached to a single synchronizer.
final class ScreenCaptureManager: NSObject {
    private let captureQueue = DispatchQueue(label: "com.paylas.capture")
    private let synchronizer: AVSampleBufferRenderSynchronizer
    /// Only used on captureQueue after init.
    private nonisolated(unsafe) let receiver: AVSampleBufferVideoRenderer.Receiver
    private var stream: SCStream?

    init(displayLayer: AVSampleBufferDisplayLayer) {
        let synchronizer = AVSampleBufferRenderSynchronizer()
        // Frames carry host clock timestamps, so let the timebase follow the host clock right away.
        synchronizer.delaysRateChangeUntilHasSufficientMediaData = false
        synchronizer.setRate(1, time: CMClock.hostTimeClock.time)
        self.synchronizer = synchronizer
        receiver = synchronizer.sampleBufferReceiver(adding: displayLayer.sampleBufferRenderer)
        super.init()
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
        stop()

        let filter = SCContentFilter(display: display, excludingWindows: [])

        let configuration = SCStreamConfiguration()
        configuration.sourceRect = cropRect
        configuration.width = max(2, Int(cropRect.width * scale))
        configuration.height = max(2, Int(cropRect.height * scale))
        configuration.showsCursor = UserDefaults.standard.object(forKey: AppSettings.showsCursorKey) as? Bool ?? AppSettings.showsCursorDefault
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.queueDepth = 5
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: 60)

        let stream = SCStream(filter: filter, configuration: configuration, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: captureQueue)
        try await stream.startCapture()

        // A newer start may have begun while we waited; don't clobber its stream.
        if Task.isCancelled {
            try? await stream.stopCapture()
            throw CancellationError()
        }
        self.stream = stream
    }

    func stop() {
        guard let stream else { return }
        self.stream = nil
        Task { try? await stream.stopCapture() }
    }
}

nonisolated extension ScreenCaptureManager: SCStreamOutput {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        // Idle frames (nothing changed on screen) carry no image.
        guard type == .screen, sampleBuffer.isValid, sampleBuffer.imageBuffer != nil else { return }

        // ScreenCaptureKit hands the buffer over and never touches it again.
        nonisolated(unsafe) let sampleBuffer = sampleBuffer
        if case .cancelledDueToFlushRequiredToResume = receiver.enqueueImmediately(CMReadySampleBuffer(unsafeBuffer: sampleBuffer)) {
            receiver.flush()
        }
    }
}

nonisolated extension ScreenCaptureManager: SCStreamDelegate {
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        logger.error("Stream wurde unerwartet beendet: \(error.localizedDescription, privacy: .public)")
    }
}

extension CGRect {
    /// Converts between bottom-left and top-left origin inside a container of the given height.
    nonisolated func flipped(inContainerHeight containerHeight: CGFloat) -> CGRect {
        CGRect(x: minX, y: containerHeight - maxY, width: width, height: height)
    }
}
