//
//  StreamWindow.swift
//  paylas
//
//  The floating window that mirrors a captured screen section live, meant to
//  be dragged onto an ultrawide monitor.
//

import AppKit
import AVFoundation

final class StreamWindowController: NSWindowController, NSWindowDelegate {
    let displayLayer = AVSampleBufferDisplayLayer()
    var onWindowClosed: (() -> Void)?

    init(title: String, contentSize: CGSize) {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 120, height: 80)

        // Keep the native resize/move/close behavior of a titled window, but hide
        // every visible trace of the title bar so only the stream content shows.
        // The traffic-light buttons only reappear while the window is key/active.
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true

        super.init(window: window)

        window.contentView = StreamContentView(displayLayer: displayLayer)
        window.delegate = self
        setWindowButtons(hidden: true)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setWindowButtons(hidden: Bool) {
        window?.standardWindowButton(.closeButton)?.isHidden = hidden
        window?.standardWindowButton(.miniaturizeButton)?.isHidden = hidden
        window?.standardWindowButton(.zoomButton)?.isHidden = hidden
    }

    func windowDidBecomeKey(_ notification: Notification) {
        setWindowButtons(hidden: false)
    }

    func windowDidResignKey(_ notification: Notification) {
        setWindowButtons(hidden: true)
    }

    func windowWillClose(_ notification: Notification) {
        onWindowClosed?()
    }
}

final class StreamContentView: NSView {
    private let displayLayer: AVSampleBufferDisplayLayer

    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
        super.init(frame: .zero)
        wantsLayer = true
        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(displayLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        displayLayer.frame = bounds
    }
}
