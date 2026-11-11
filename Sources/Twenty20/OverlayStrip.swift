import SwiftUI

/// Shared observable state for every per-screen strip.
@MainActor
final class BreakViewModel: ObservableObject {
    @Published private(set) var countdown: Int = 0
    @Published private(set) var canSkip: Bool = false
    var onSkip: (() -> Void)?

    private let skipGraceSeconds = 2
    private var elapsed = 0

    func update(remaining: Int, duration: Int) {
        countdown = remaining
        elapsed = max(0, duration - remaining)
        canSkip = elapsed >= skipGraceSeconds
    }
}

struct OverlayStrip: View {
    @ObservedObject var viewModel: BreakViewModel

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "eye")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Look 20 feet away")
                    .font(.headline)
                Text("Give your eyes a break")
                    .font(.subheadline)
                    .opacity(0.75)
            }
            Spacer()
            Text("\(viewModel.countdown)s")
                .font(.system(.title2, design: .rounded).bold())
                .monospacedDigit()
            Button("Skip") { viewModel.onSkip?() }
                .disabled(!viewModel.canSkip)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.92))
        .foregroundStyle(.white)
    }
}
