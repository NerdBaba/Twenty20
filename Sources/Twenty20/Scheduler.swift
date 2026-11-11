import Foundation

/// What the scheduler asks the overlay layer to do. Abstracted so the
/// scheduler is testable without AppKit.
@MainActor
protocol OverlayControlling: AnyObject {
    func showBreak()
    func hideBreak()
    /// `remaining`/`duration` in whole seconds, for the on-overlay countdown.
    func updateCountdown(remaining: Int, duration: Int)
}

/// Two-state machine: `waiting` counts down the work interval (paused while
/// the user is idle), `onBreak` shows the overlay for the break duration
/// (also pauseable while idle, capped so a break can't stretch forever).
///
/// Timing is tick-based, not deadline-based: a 1 s timer decrements stored
/// remainders by measured uptime deltas. Sleep suspends the timer, so sleep
/// time never counts — no wake recomputation needed.
@MainActor
final class Scheduler {
    enum Phase: Equatable {
        case waiting
        case onBreak
    }

    private(set) var phase: Phase = .waiting
    private(set) var workRemaining: TimeInterval
    private(set) var breakRemaining: TimeInterval = 0

    /// Whole seconds until the next state change, for menu-bar display.
    var displaySeconds: Int {
        Int(ceil(phase == .onBreak ? breakRemaining : workRemaining))
    }

    var isOnBreak: Bool { phase == .onBreak }

    private let config: @MainActor () -> SchedulerConfig
    private let idleSeconds: @MainActor () -> TimeInterval
    private let now: @MainActor () -> TimeInterval
    private weak var overlay: (any OverlayControlling)?

    var onChange: (() -> Void)?

    private var timer: Timer?
    private var lastTick: TimeInterval
    /// Idle time credited against the current break, capped so stepping away
    /// mid-break can't stretch it indefinitely.
    private var breakIdleCredit: TimeInterval = 0
    private let breakIdleCap: TimeInterval = 60
    /// Duration of the currently active break, so countdown math stays
    /// correct even when it differs from the configured default (demo breaks).
    private var activeBreakDuration: TimeInterval = 0

    init(
        config: @escaping @MainActor () -> SchedulerConfig,
        idleSeconds: @escaping @MainActor () -> TimeInterval,
        now: @escaping @MainActor () -> TimeInterval = { ProcessInfo.processInfo.systemUptime },
        overlay: (any OverlayControlling)? = nil
    ) {
        self.config = config
        self.idleSeconds = idleSeconds
        self.now = now
        self.overlay = overlay
        self.lastTick = now()
        self.workRemaining = config().workInterval
    }

    func start() {
        guard timer == nil else { return }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: - Controls (menu / overlay)

    func triggerBreakNow() {
        guard phase == .waiting else { return }
        beginBreak()
    }

    /// Ends the break early and resets the work countdown to a full interval.
    func skipBreak() {
        guard phase == .onBreak else { return }
        endBreak()
    }

    /// Pushes the next break out — sets remaining work time to at least `duration`.
    func pause(for duration: TimeInterval) {
        guard phase == .waiting else { return }
        workRemaining = max(workRemaining, duration)
        notify()
    }

    /// Launch-arg smoke test: shows a short break immediately.
    func demoBreak(duration: TimeInterval = 8) {
        phase = .onBreak
        breakRemaining = duration
        activeBreakDuration = duration
        breakIdleCredit = 0
        overlay?.showBreak()
        overlay?.updateCountdown(
            remaining: Int(ceil(breakRemaining)),
            duration: Int(ceil(activeBreakDuration))
        )
        notify()
    }

    // MARK: - Tick

    /// Advances the state machine by the elapsed time since the previous tick.
    /// Internal (not private) so tests can drive it with a fake clock.
    func tick() {
        let timestamp = now()
        let elapsed = max(0, timestamp - lastTick)
        lastTick = timestamp
        guard elapsed > 0 else { notify(); return }

        let cfg = config()
        let isIdle = idleSeconds() >= cfg.idleThreshold

        switch phase {
        case .waiting:
            if !isIdle {
                workRemaining = max(0, workRemaining - elapsed)
            }
            if workRemaining <= 0 {
                beginBreak()
                return
            }
        case .onBreak:
            if isIdle, breakIdleCredit < breakIdleCap {
                breakIdleCredit += elapsed
            } else {
                breakRemaining = max(0, breakRemaining - elapsed)
            }
            if breakRemaining <= 0 {
                endBreak()
                return
            }
        }

        overlay?.updateCountdown(
            remaining: displaySeconds,
            duration: Int(ceil(phase == .onBreak ? activeBreakDuration : cfg.workInterval))
        )
        notify()
    }

    // MARK: - Transitions

    private func beginBreak() {
        phase = .onBreak
        breakRemaining = config().breakDuration
        activeBreakDuration = breakRemaining
        breakIdleCredit = 0
        overlay?.showBreak()
        overlay?.updateCountdown(
            remaining: Int(ceil(breakRemaining)),
            duration: Int(ceil(activeBreakDuration))
        )
        notify()
    }

    private func endBreak() {
        overlay?.hideBreak()
        phase = .waiting
        workRemaining = config().workInterval
        notify()
    }

    private func notify() {
        onChange?()
    }
}
