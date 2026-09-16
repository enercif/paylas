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
        window.level = .floating // always on top

        // Keep the native resize/move/close behavior of a titled window, but hide
        // every visible trace of the title bar so only the stream content shows.
        // The traffic-light buttons stay hidden; StreamContentView shows its own
        // close button on hover instead.
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true

        super.init(window: window)

        window.contentView = StreamContentView(displayLayer: displayLayer)
        window.delegate = self
        for type: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(type)?.isHidden = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func windowWillClose(_ notification: Notification) {
        onWindowClosed?()
    }
}

final class StreamContentView: NSView {
    private let displayLayer: AVSampleBufferDisplayLayer
    private let closeButton = NSButton()

    init(displayLayer: AVSampleBufferDisplayLayer) {
        self.displayLayer = displayLayer
        super.init(frame: .zero)
        wantsLayer = true // backed by displayLayer, see makeBackingLayer()
        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = NSColor.black.cgColor

        let symbolConfig = NSImage.SymbolConfiguration(pointSize: 20, weight: .regular)
            .applying(.init(paletteColors: [.white, NSColor.black.withAlphaComponent(0.6)]))
        closeButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Stream schließen")?
            .withSymbolConfiguration(symbolConfig)
        closeButton.isBordered = false
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        closeButton.isHidden = true
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        ])

        // .activeAlways: Paylas is a menu bar app, so the window is usually not key.
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseEntered(with event: NSEvent) {
        closeButton.isHidden = false
    }

    override func mouseExited(with event: NSEvent) {
        closeButton.isHidden = true
    }

    @objc private func closeWindow() {
        window?.close()
    }

    override func makeBackingLayer() -> CALayer {
        displayLayer
    }
}
