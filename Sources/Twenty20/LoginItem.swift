import Foundation
import ServiceManagement

/// Launch-at-login via SMAppService (macOS 13+). Requires the app to run
/// from a proper .app bundle — `swift run` dev mode reports `.notFound`.
enum LoginItem {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
