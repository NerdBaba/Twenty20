import AppKit

/// Rebuilds overlays when displays are plugged/unplugged or rearranged.
@MainActor
final class ScreenWatcher {
    nonisolated(unsafe) private var token: NSObjectProtocol?

    init(onChange: @escaping @MainActor () -> Void) {
        token = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in onChange() }
        }
    }

    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}
