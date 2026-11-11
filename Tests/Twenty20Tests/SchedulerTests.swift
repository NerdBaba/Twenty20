import XCTest
@testable import Twenty20

/// Each test builds its own scheduler with a fake clock and fake idle
/// monitor; `advance(_:)` moves time forward and ticks once.
@MainActor
final class SchedulerTests: XCTestCase {
    @MainActor
    private final class Rig {
        /// Mutable fake clock; nonisolated so escaping closures can capture it.
        final class Clock {
            var now: TimeInterval = 0
            var idle: TimeInterval = 0
        }

        let clock = Clock()
        let overlay = FakeOverlay()
        let scheduler: Scheduler

        init(workInterval: TimeInterval = 100, breakDuration: TimeInterval = 20, idleThreshold: TimeInterval = 60) {
            let clockBox = clock
            scheduler = Scheduler(
                config: {
                    SchedulerConfig(workInterval: workInterval, breakDuration: breakDuration, idleThreshold: idleThreshold)
                },
                idleSeconds: { clockBox.idle },
                now: { clockBox.now },
                overlay: overlay
            )
        }

        func advance(_ seconds: TimeInterval) {
            clock.now += seconds
            scheduler.tick()
        }
    }

    func testBreakStartsAfterWorkInterval() {
        let rig = Rig()
        XCTAssertEqual(rig.scheduler.phase, .waiting)
        rig.advance(99)
        XCTAssertEqual(rig.scheduler.phase, .waiting)
        rig.advance(1)
        XCTAssertEqual(rig.scheduler.phase, .onBreak)
        XCTAssertEqual(rig.overlay.showCount, 1)
        XCTAssertEqual(rig.scheduler.breakRemaining, 20, accuracy: 0.001)
    }

    func testBreakAutoEndsAndResetsWorkTimer() {
        let rig = Rig()
        rig.advance(100)
        XCTAssertEqual(rig.scheduler.phase, .onBreak)
        rig.advance(19)
        XCTAssertEqual(rig.scheduler.phase, .onBreak)
        rig.advance(1)
        XCTAssertEqual(rig.scheduler.phase, .waiting)
        XCTAssertEqual(rig.scheduler.workRemaining, 100, accuracy: 0.001)
        XCTAssertEqual(rig.overlay.hideCount, 1)
    }

    func testIdlePausesWorkCountdown() {
        let rig = Rig()
        rig.advance(50)
        rig.clock.idle = 120 // over the 60s threshold
        rig.advance(500)
        XCTAssertEqual(rig.scheduler.workRemaining, 50, accuracy: 0.001)
        XCTAssertEqual(rig.scheduler.phase, .waiting)
        rig.clock.idle = 0
        rig.advance(50)
        XCTAssertEqual(rig.scheduler.phase, .onBreak)
    }

    func testIdleDuringBreakExtendsButIsCapped() {
        let rig = Rig()
        rig.advance(100)
        XCTAssertEqual(rig.scheduler.phase, .onBreak)
        rig.clock.idle = 120
        // 60s of idle credit freezes the countdown entirely
        rig.advance(60)
        XCTAssertEqual(rig.scheduler.breakRemaining, 20, accuracy: 0.001)
        // beyond the cap, the countdown resumes and the break ends
        rig.advance(20)
        XCTAssertEqual(rig.scheduler.phase, .waiting)
        XCTAssertEqual(rig.overlay.hideCount, 1)
    }

    func testSkipBreakResetsWorkTimerToFull() {
        let rig = Rig()
        rig.advance(100)
        rig.advance(5)
        rig.scheduler.skipBreak()
        XCTAssertEqual(rig.scheduler.phase, .waiting)
        XCTAssertEqual(rig.scheduler.workRemaining, 100, accuracy: 0.001)
        XCTAssertEqual(rig.overlay.hideCount, 1)
    }

    func testSkipIgnoredWhileWaiting() {
        let rig = Rig()
        rig.advance(50)
        rig.scheduler.skipBreak()
        XCTAssertEqual(rig.scheduler.phase, .waiting)
        XCTAssertEqual(rig.scheduler.workRemaining, 50, accuracy: 0.001)
    }

    func testBreakNowForcesBreak() {
        let rig = Rig()
        rig.advance(10)
        rig.scheduler.triggerBreakNow()
        XCTAssertEqual(rig.scheduler.phase, .onBreak)
        XCTAssertEqual(rig.overlay.showCount, 1)
        rig.scheduler.triggerBreakNow()
        XCTAssertEqual(rig.overlay.showCount, 1)
    }

    func testPauseSetsMinimumRemaining() {
        let rig = Rig()
        rig.advance(90)
        rig.scheduler.pause(for: 1800)
        XCTAssertEqual(rig.scheduler.workRemaining, 1800, accuracy: 0.001)
        rig.advance(1800)
        XCTAssertEqual(rig.scheduler.phase, .onBreak)
    }

    func testDemoBreakUsesGivenDuration() {
        let rig = Rig()
        rig.scheduler.demoBreak(duration: 8)
        XCTAssertEqual(rig.scheduler.phase, .onBreak)
        XCTAssertEqual(rig.scheduler.breakRemaining, 8, accuracy: 0.001)
        rig.advance(8)
        XCTAssertEqual(rig.scheduler.phase, .waiting)
    }

    func testCountdownUpdatesPropagateToOverlay() {
        let rig = Rig()
        rig.advance(100)
        let last = rig.overlay.lastCountdown
        XCTAssertNotNil(last)
        XCTAssertEqual(last?.remaining, 20)
        XCTAssertEqual(last?.duration, 20)
    }
}

@MainActor
private final class FakeOverlay: OverlayControlling {
    var showCount = 0
    var hideCount = 0
    var lastCountdown: (remaining: Int, duration: Int)?

    func showBreak() { showCount += 1 }
    func hideBreak() { hideCount += 1 }
    func updateCountdown(remaining: Int, duration: Int) {
        lastCountdown = (remaining, duration)
    }
}
