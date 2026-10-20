import AppKit
import SwiftUI

/// Five-step setup in one focused column under integrated window chrome, with a stable footer.
struct OnboardingView: View {
    @ObservedObject var model: AppModel
    let onFinish: () -> Void
    @State private var step: OnboardingStep = .welcome
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: AppModel, onFinish: @escaping () -> Void) {
        self.model = model
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                WindowDragArea()
                OnboardingProgress(current: step)
            }
            .frame(height: HostingWindowController.chromeHeight)

            ScrollView {
                content
                    .id(step)
                    .transition(.opacity)
                    .padding(.horizontal, 40)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            RowDivider()
            footer
                .padding(.horizontal, 40)
                .padding(.vertical, 14)
        }
        .background(AppPalette.canvas)
        .animation(AppMotion.reveal(reduceMotion), value: step)
        .frame(minWidth: 600, idealWidth: 660, minHeight: 480, idealHeight: 520)
        .onAppear {
            model.refreshStatus()
            if model.isPracticeSession { step = .practice }
            if step == .practice { model.beginPractice() }
        }
        .onDisappear { model.endPractice() }
        .onChange(of: step) { newStep in
            // Entering Try it enables the practice context without starting the microphone.
            if newStep == .practice { model.beginPractice() } else { model.endPractice() }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refreshStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            model.refreshStatus()
        }
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .welcome: OnboardingWelcomeStep(model: model)
        case .permissions: OnboardingPermissionsStep(model: model)
        case .shortcut: OnboardingShortcutStep(model: model)
        case .practice: OnboardingPracticeStep(model: model) { step = $0 }
        case .ready: OnboardingReadyStep(model: model) { step = $0 }
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if let previous = step.previous {
                Button("Back") { step = previous }
                    .buttonStyle(AppButtonStyle(kind: .quiet))
                    .keyboardShortcut(.cancelAction)
            }
            Spacer()
            if let next = step.next {
                mainButton(pending ? "Skip for now" : "Continue", arrow: true) { step = next }
            } else {
                mainButton(model.missingRequirements.isEmpty ? "Done" : "Finish later", arrow: false) {
                    model.endPractice()
                    model.completeOnboarding()
                    onFinish()
                }
            }
        }
    }

    /// The footer action is the main action only when the step has no other pending main action.
    @ViewBuilder
    private func mainButton(_ title: String, arrow: Bool, action: @escaping () -> Void) -> some View {
        if pending {
            Button(title, action: action)
                .buttonStyle(AppButtonStyle(kind: .secondary))
        } else {
            Button(title, action: action)
                .buttonStyle(AppButtonStyle(kind: .primary, showsArrow: arrow))
                .keyboardShortcut(.defaultAction)
        }
    }

    private var pending: Bool {
        switch step {
        case .welcome: return !model.connection.isUsable
        case .permissions: return model.microphone != .granted
        case .practice: return model.practiceTranscript == nil
        case .shortcut, .ready: return false
        }
    }
}
