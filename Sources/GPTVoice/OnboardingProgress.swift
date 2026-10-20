import SwiftUI

/// Quiet step indicator: "2 of 5" and the step name, with five short segments. Only the current one is filled.
/// Position is shown, never completion.
struct OnboardingProgress: View {
    let current: OnboardingStep
    @Environment(\.appAccentFill) private var accentFill

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                ForEach(OnboardingStep.allCases) { step in
                    Capsule()
                        .fill(step == current ? accentFill : AppPalette.well)
                        .frame(width: step == current ? 18 : 10, height: 3)
                }
            }
            Text("\(current.rawValue + 1) of \(OnboardingStep.allCases.count)  \(current.label)")
                .font(AppType.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current.rawValue + 1) of \(OnboardingStep.allCases.count): \(current.label)")
    }
}
