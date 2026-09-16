//
//  StreamBorderWindow.swift
//  paylas
//
//  Click-through window that draws a dashed border around the captured
//  section. The border sits just outside the capture rect so it never shows
//  up in the stream itself. Enabled state and color follow the settings live.
//

import AppKit
import SwiftUI

final class StreamBorderWindow: NSWindow {
    private static let lineWidth: CGFloat = 2

    /// - Parameter rect: The captured section in the screen's local (bottom-left origin) coordinates.
    init(rect: CGRect, screen: NSScreen) {
        // 1pt gap between border and capture rect so no border pixel gets captured.
        let frame = rect
            .offsetBy(dx: screen.frame.minX, dy: screen.frame.minY)
            .insetBy(dx: -(Self.lineWidth + 1), dy: -(Self.lineWidth + 1))
        super.init(contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        isReleasedWhenClosed = false
        contentView = NSHostingView(rootView: StreamBorderView(lineWidth: Self.lineWidth))
    }
}

private struct StreamBorderView: View {
    let lineWidth: CGFloat
    @AppStorage(AppSettings.showsBorderKey) private var showsBorder = true
    @AppStorage(AppSettings.borderColorKey) private var borderColor = Color.blue

    var body: some View {
        if showsBorder {
            Rectangle()
                .strokeBorder(borderColor, style: StrokeStyle(lineWidth: lineWidth, dash: [6, 4]))
        }
    }
}
