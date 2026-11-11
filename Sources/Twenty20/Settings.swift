import Foundation

/// Snapshot of user-tunable timing values, read live from UserDefaults.
struct SchedulerConfig: Equatable {
    var workInterval: TimeInterval
    var breakDuration: TimeInterval
    var idleThreshold: TimeInterval
}

enum AppSettings {
    static let workIntervalKey = "workIntervalMinutes"
    static let breakDurationKey = "breakDurationSeconds"
    static let idleThresholdKey = "idleThresholdSeconds"

    static let defaultWorkIntervalMinutes: Double = 20
    static let defaultBreakDurationSeconds: Double = 20
    static let defaultIdleThresholdSeconds: Double = 60

    /// Reads UserDefaults with clamping so hand-edited values can't
    /// produce zero/negative intervals (which would break-loop the scheduler).
    static var current: SchedulerConfig {
        let defaults = UserDefaults.standard
        return SchedulerConfig(
            workInterval: clamp(defaults.object(forKey: workIntervalKey) as? Double ?? defaultWorkIntervalMinutes, 1...720) * 60,
            breakDuration: clamp(defaults.object(forKey: breakDurationKey) as? Double ?? defaultBreakDurationSeconds, 1...600),
            idleThreshold: clamp(defaults.object(forKey: idleThresholdKey) as? Double ?? defaultIdleThresholdSeconds, 1...3600)
        )
    }

    private static func clamp(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
