//
//  StreamWindow.swift
//  paylas
//
//  The floating window that mirrors a captured screen section live, meant to
//  be dragged onto an ultrawide monitor.
//

import AppKit
import AVFoundation
import CoreImage.CIFilterBuiltins

final class StreamWindowController: NSWindowController, NSWindowDelegate {
    let displayLayer = AVSampleBufferDisplayLayer()
    private let contentView: StreamContentView
    var onWindowClosed: (() -> Void)?

    var isBlurred: Bool {
        get { contentView.isBlurred }
        set { contentView.isBlurred = newValue }
    }

    var onToggleBlur: (() -> Void)? {
        get { contentView.onToggleBlur }
        set { contentView.onToggleBlur = newValue }
    }

    init(contentSize: CGSize) {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "paylas"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 120, height: 80)
        // Normal level on purpose: Discord/Chromium window pickers only list layer-0 windows.

        // Keep the native resize/move/close behavior of a titled window, but hide
        // every visible trace of the title bar so only the stream content shows.
        // The traffic-light buttons stay hidden; StreamContentView shows its own
        // close and blur buttons on hover instead.
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true

        contentView = StreamContentView(displayLayer: displayLayer)
        super.init(window: window)

        window.contentView = contentView
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
    private static let blurRadius = 40.0
    private static let symbolConfig = NSImage.SymbolConfiguration(pointSize: 20, weight: .regular)
        .applying(.init(paletteColors: [.white, NSColor.black.withAlphaComponent(0.6)]))

    private let videoView = NSView()
    private let buttons = NSStackView()
    private let blurButton = NSButton()
    var onToggleBlur: (() -> Void)?

    var isBlurred = false {
        didSet {
            let blur = CIFilter.gaussianBlur()
            blur.radius = Float(Self.blurRadius)
            videoView.layer?.filters = isBlurred ? [blur] : nil
            blurButton.image = Self.symbol(
                isBlurred ? "eye.circle.fill" : "eye.slash.circle.fill",
                isBlurred ? "Stream scharf schalten" : "Stream unscharf schalten"
            )
        }
    }

    init(displayLayer: AVSampleBufferDisplayLayer) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        displayLayer.videoGravity = .resizeAspect
        displayLayer.backgroundColor = NSColor.black.cgColor

        // Layer-hosting view (layer set before wantsLayer), a sibling of the
        // buttons, so the blur filter only hits the video.
        videoView.layer = displayLayer
        videoView.wantsLayer = true
        videoView.layerUsesCoreImageFilters = true
        videoView.autoresizingMask = [.width, .height]
        addSubview(videoView)

        let closeButton = NSButton()
        closeButton.image = Self.symbol("xmark.circle.fill", "Stream schließen")
        closeButton.target = self
        closeButton.action = #selector(closeWindow)
        blurButton.image = Self.symbol("eye.slash.circle.fill", "Stream unscharf schalten")
        blurButton.target = self
        blurButton.action = #selector(toggleBlur)
        for button in [closeButton, blurButton] {
            button.isBordered = false
            buttons.addArrangedSubview(button)
        }

        buttons.spacing = 4
        buttons.isHidden = true
        buttons.translatesAutoresizingMaskIntoConstraints = false
        addSubview(buttons)
        NSLayoutConstraint.activate([
            buttons.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            buttons.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8)
        ])

        // .activeAlways: Paylas is a menu bar app, so the window is usually not key.
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func mouseEntered(with event: NSEvent) {
        buttons.isHidden = false
    }

    override func mouseExited(with event: NSEvent) {
        buttons.isHidden = true
    }

    @objc private func closeWindow() {
        window?.close()
    }

    @objc private func toggleBlur() {
        onToggleBlur?()
    }

    private static func symbol(_ name: String, _ description: String) -> NSImage? {
        NSImage(systemSymbolName: name, accessibilityDescription: description)?.withSymbolConfiguration(symbolConfig)
    }
}
