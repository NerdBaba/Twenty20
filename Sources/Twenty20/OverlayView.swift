import AppKit
import SwiftUI

/// Borderless panel that never activates the app and never takes focus.
/// Style mask is fixed at init — toggling `.nonactivatingPanel` later
/// silently breaks the WindowServer activation tag (FB16484811).
final class BreakPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        becomesKeyOnlyIfNeeded = true
    }

    /// AppKit clamps frames to `visibleFrame` by default, which would push
    /// the strip below the menu bar. The strip must cover it.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}
