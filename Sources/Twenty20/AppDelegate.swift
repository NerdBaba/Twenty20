import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var scheduler: Scheduler!
    private var overlay: OverlayController!
    private var statusItem: StatusItemController!
    private var screenWatcher: ScreenWatcher!
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let idleMonitor = SystemIdleMonitor()

        overlay = OverlayController()
        scheduler = Scheduler(
            config: { AppSettings.current },
            idleSeconds: { idleMonitor.idleSeconds() },
            overlay: overlay
        )
        overlay.onSkip = { [weak self] in self?.scheduler.skipBreak() }
        scheduler.onChange = { [weak self] in self?.statusItem?.refresh() }

        statusItem = StatusItemController(scheduler: scheduler) { [weak self] action in
            self?.handle(action)
        }
        screenWatcher = ScreenWatcher { [weak self] in
            self?.overlay.rebuild()
        }

        scheduler.start()

        if CommandLine.arguments.contains("--twenty20-demo") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.scheduler.demoBreak()
            }
        }

        // Maintenance flag: (re)registers the login item for THIS bundle path,
        // then quits. Useful after moving the .app (e.g. into /Applications).
        if CommandLine.arguments.contains("--twenty20-login-test") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Unregister first: register() alone is a no-op when the item
                // already exists and would keep the stale bundle URL.
                try? LoginItem.setEnabled(false)
                do {
                    try LoginItem.setEnabled(true)
                    NSLog("Twenty20 login-test: register ok, enabled=%@", "\(LoginItem.isEnabled)")
                } catch {
                    NSLog("Twenty20 login-test: register failed: %@", "\(error)")
                }
                NSApp.terminate(nil)
            }
        }
    }
    private func handle(_ action: StatusItemController.Action) {
        switch action {
        case .breakNow:
            scheduler.triggerBreakNow()
        case .skipBreak:
            scheduler.skipBreak()
        case .pause30:
            scheduler.pause(for: 30 * 60)
        case .toggleLogin:
            toggleLoginItem()
        case .settings:
            showSettings()
        case .quit:
            NSApp.terminate(nil)
        }
    }

    private func toggleLoginItem() {
        do {
            try LoginItem.setEnabled(!LoginItem.isEnabled)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't update login item"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        statusItem.reloadLoginState()
    }

    private func showSettings() {
        if settingsWindow == nil {
            let host = NSHostingView(rootView: SettingsView())
            host.layoutSubtreeIfNeeded()
            let fitting = host.fittingSize
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: max(340, fitting.width), height: max(160, fitting.height)),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Twenty20 Settings"
            window.contentView = host
            window.center()
            window.isReleasedWhenClosed = false
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate()
}
}
