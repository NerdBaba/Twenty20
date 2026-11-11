import SwiftUI

struct SettingsView: View {
    @AppStorage(AppSettings.workIntervalKey) private var workMinutes = AppSettings.defaultWorkIntervalMinutes
    @AppStorage(AppSettings.breakDurationKey) private var breakSeconds = AppSettings.defaultBreakDurationSeconds
    @AppStorage(AppSettings.idleThresholdKey) private var idleSeconds = AppSettings.defaultIdleThresholdSeconds

    var body: some View {
        Form {
            Stepper("Work interval: \(Int(workMinutes)) min", value: $workMinutes, in: 5...120, step: 5)
            Stepper("Break duration: \(Int(breakSeconds)) s", value: $breakSeconds, in: 5...120, step: 5)
            Stepper("Idle threshold: \(Int(idleSeconds)) s", value: $idleSeconds, in: 10...300, step: 10)
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 340)
    }
}
