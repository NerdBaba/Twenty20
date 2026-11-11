import AppKit
import SwiftUI

/// Owns one borderless non-activating panel per screen and shows/hides them
/// as a top-of-screen strip during breaks.
@MainActor
final class OverlayController: OverlayControlling {
    var onSkip: (() -> Void)?

    private let viewModel = BreakViewModel()
    private var panels: [BreakPanel] = []
    private var screenSignature: [NSRect] = []
    private var isShowing = false

    init() {
        viewModel.onSkip = { [weak self] in self?.onSkip?() }
    }

    // MARK: - OverlayControlling

    func showBreak() {
        syncPanels()
        for panel in panels {
            panel.orderFrontRegardless()
        }
        isShowing = true
    }

    func hideBreak() {
        for panel in panels {
            panel.orderOut(nil)
        }
        isShowing = false
    }

    func updateCountdown(remaining: Int, duration: Int) {
        viewModel.update(remaining: remaining, duration: duration)
    }

    /// Tears down and rebuilds panels (call on screen-parameter changes).
    /// If a break is currently showing, the new panels are shown immediately.
    func rebuild() {
        let wasShowing = isShowing
        hideBreak()
        panels.removeAll()
        screenSignature = []
        if wasShowing {
            showBreak()
        }
    }

    // MARK: - Panels

    /// Covers the menu-bar strip: full width, anchored to the top of
    /// `screen.frame` (not `visibleFrame`, which excludes the menu bar).
    private static var stripHeight: CGFloat {
        max(72, NSStatusBar.system.thickness + 24)
    }

    private func syncPanels() {
        let screens = NSScreen.screens
        let signature = screens.map(\.frame)
        guard signature != screenSignature || panels.isEmpty else { return }

        for panel in panels { panel.orderOut(nil) }
        panels = screens.map { makePanel(for: $0) }
        screenSignature = signature
    }

    private func makePanel(for screen: NSScreen) -> BreakPanel {
        let stripHeight = Self.stripHeight
        let rect = NSRect(
            x: screen.frame.minX,
            y: screen.frame.maxY - stripHeight,
            width: screen.frame.width,
            height: stripHeight
        )
        let panel = BreakPanel(contentRect: rect)
        let host = NSHostingView(rootView: OverlayStrip(viewModel: viewModel))
        host.frame = NSRect(origin: .zero, size: rect.size)
        host.autoresizingMask = [.width, .height]
        panel.contentView = host
        return panel
    }
}
