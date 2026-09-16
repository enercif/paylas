//
//  SectionSelectorOverlay.swift
//  paylas
//
//  A borderless, transparent full-screen overlay used to drag out a
//  rectangular section of the screen, similar to Cmd+Shift+4.
//

import AppKit
import Carbon.HIToolbox

final class SectionSelectorOverlay {
    private var window: SectionSelectorWindow?

    /// Presents the overlay on the given screen. The completion handler receives
    /// the selected rect in that screen's local (bottom-left origin) coordinate
    /// space, or nil if the selection was cancelled.
    func present(on screen: NSScreen, completion: @escaping (CGRect?) -> Void) {
        dismiss()

        let window = SectionSelectorWindow(screen: screen)
        let view = SectionSelectorView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.onSelectionComplete = { [weak self] rect in
            self?.dismiss()
            completion(rect)
        }
        view.onCancel = { [weak self] in
            self?.dismiss()
            completion(nil)
        }
        window.contentView = view

        self.window = window
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func dismiss() {
        window?.orderOut(nil)
        window = nil
    }
}

final class SectionSelectorWindow: NSWindow {
    init(screen: NSScreen) {
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .screenSaver
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
}

final class SectionSelectorView: NSView {
    var onSelectionComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: NSRect?

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        startPoint = point
        currentRect = NSRect(origin: point, size: .zero)
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let point = convert(event.locationInWindow, from: nil)
        currentRect = NSRect(
            x: min(start.x, point.x),
            y: min(start.y, point.y),
            width: abs(point.x - start.x),
            height: abs(point.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        defer { startPoint = nil }
        guard let rect = currentRect, rect.width >= 4, rect.height >= 4 else {
            onCancel?()
            return
        }
        onSelectionComplete?(rect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == kVK_Escape {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        NSColor.black.withAlphaComponent(0.45).setFill()
        bounds.fill()

        guard let rect = currentRect, rect.width > 0, rect.height > 0 else { return }

        context.saveGState()
        context.setBlendMode(.clear)
        context.fill(rect)
        context.restoreGState()

        NSColor.white.setStroke()
        let border = NSBezierPath(rect: rect)
        border.lineWidth = 1.5
        border.stroke()

        drawSizeLabel(for: rect)
    }

    private func drawSizeLabel(for rect: NSRect) {
        let text = "\(Int(rect.width)) × \(Int(rect.height))"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white
        ]
        let textSize = text.size(withAttributes: attributes)
        let padding: CGFloat = 4
        var labelOrigin = NSPoint(x: rect.minX, y: rect.maxY + 6)
        if labelOrigin.y + textSize.height + padding * 2 > bounds.maxY {
            labelOrigin.y = rect.minY - textSize.height - padding * 2 - 6
        }
        let labelRect = NSRect(x: labelOrigin.x, y: labelOrigin.y, width: textSize.width + padding * 2, height: textSize.height + padding * 2)
        NSColor.black.withAlphaComponent(0.6).setFill()
        NSBezierPath(roundedRect: labelRect, xRadius: 4, yRadius: 4).fill()
        text.draw(at: NSPoint(x: labelRect.minX + padding, y: labelRect.minY + padding), withAttributes: attributes)
    }
}
