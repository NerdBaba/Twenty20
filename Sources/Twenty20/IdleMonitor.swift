import CoreGraphics
import Foundation

/// Seconds since the last user input event, system-wide, no permissions required.
protocol IdleMonitoring {
    func idleSeconds() -> TimeInterval
}

struct SystemIdleMonitor: IdleMonitoring {
    /// `kCGAnyInputEventType` (~0) — the "any event" sentinel; not imported as a Swift member.
    private static let anyInputEvent = CGEventType(rawValue: ~0)!

    func idleSeconds() -> TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: Self.anyInputEvent)
    }
}
