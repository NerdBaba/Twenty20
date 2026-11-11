import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    enum Action {
        case breakNow
        case skipBreak
        case pause30
        case toggleLogin
        case settings
        case quit
    }

    private let statusItem: NSStatusItem
    private let scheduler: Scheduler
    private let handler: (Action) -> Void
    private var lastTitle = ""
    /// Cached login-item state — SMAppService.status is an XPC call, so it
    /// must not run on every scheduler tick. Refreshed on menu open/toggle.
    private var loginEnabled = false

    private var breakNowItem: NSMenuItem!
    private var skipItem: NSMenuItem!
    private var pauseItem: NSMenuItem!
    private var loginItem: NSMenuItem!

    init(scheduler: Scheduler, handler: @escaping (Action) -> Void) {
        self.scheduler = scheduler
        self.handler = handler
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        statusItem.button?.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Twenty20")
        statusItem.button?.image?.isTemplate = true

        let menu = NSMenu()
        let breakNow = NSMenuItem(title: "Break now", action: #selector(dispatchBreakNow), keyEquivalent: "b")
        let skip = NSMenuItem(title: "Skip break", action: #selector(dispatchSkip), keyEquivalent: "")
        let pause = NSMenuItem(title: "Pause for 30 min", action: #selector(dispatchPause), keyEquivalent: "")
        let login = NSMenuItem(title: "Launch at login", action: #selector(dispatchLogin), keyEquivalent: "")
        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(dispatchSettings), keyEquivalent: ",")
        let quitItem = NSMenuItem(title: "Quit Twenty20", action: #selector(dispatchQuit), keyEquivalent: "q")
        breakNowItem = breakNow
        skipItem = skip
        pauseItem = pause
        loginItem = login
        for item in [breakNow, skip, pause] {
            item.target = self
            menu.addItem(item)
        }
        menu.addItem(.separator())
        for item in [login, settingsItem] {
            item.target = self
            menu.addItem(item)
        }
        menu.addItem(.separator())
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu
        menu.delegate = self
        reloadLoginState()
    }

    /// SMAppService.status is an XPC to loginitemsd — only call it when the
    /// menu opens or after a toggle, never on the per-second scheduler tick.
    func reloadLoginState() {
        loginEnabled = LoginItem.isEnabled
        loginItem.state = loginEnabled ? .on : .off
    }

    func menuWillOpen(_ menu: NSMenu) {
        reloadLoginState()
    }

    /// Called by the scheduler on every tick; only touches AppKit when the
    /// displayed second or enabled states actually change.
    func refresh() {
        let seconds = scheduler.displaySeconds
        let title = scheduler.isOnBreak ? "BREAK \(Self.format(seconds))" : Self.format(seconds)
        if title != lastTitle {
            lastTitle = title
            statusItem.button?.title = title
        }
        breakNowItem.isEnabled = !scheduler.isOnBreak
        skipItem.isEnabled = scheduler.isOnBreak
        pauseItem.isEnabled = !scheduler.isOnBreak
        loginItem.state = loginEnabled ? .on : .off
    }

    private static func format(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    @objc private func dispatchBreakNow() { handler(.breakNow) }
    @objc private func dispatchSkip() { handler(.skipBreak) }
    @objc private func dispatchPause() { handler(.pause30) }
    @objc private func dispatchLogin() { handler(.toggleLogin) }
    @objc private func dispatchSettings() { handler(.settings) }
    @objc private func dispatchQuit() { handler(.quit) }
}
