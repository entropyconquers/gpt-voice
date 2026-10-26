import Foundation

/// Tracks a press-and-hold of one modifier key.
/// Recording starts only after `commit`, so a tap or a chord never opens the microphone.
/// A chord or click before that point disarms the hold. Another key after it cancels the session.
struct ModifierHoldTracker {
    /// Wait before treating the press as a hold. Option chords usually arrive inside this window.
    static let minimumHold: TimeInterval = 0.2

    enum Action: Equatable {
        case none
        /// The watched key went down alone. Start the hold timer.
        case arm
        /// The press ended before it became a hold. Cancel the timer.
        case disarm
        /// The key was released after recording should have started.
        case end
        /// Another key arrived after the hold began. Discard the recording.
        case cancelSession
    }

    let keyCode: UInt32
    private enum State { case idle, pending, holding }
    private var state = State.idle

    init(keyCode: UInt32) {
        self.keyCode = keyCode
    }

    mutating func reset() { state = .idle }

    /// Marks the hold as real. Returns false when it was already cancelled.
    mutating func commit() -> Bool {
        guard state == .pending else { return false }
        state = .holding
        return true
    }

    mutating func consume(eventKeyCode: UInt32?, modifierDown: Bool, otherModifierDown: Bool,
                          cancelsHold: Bool) -> Action {
        if cancelsHold || otherModifierDown { return chordFromKey() }
        guard eventKeyCode == keyCode else { return .none }
        if modifierDown {
            guard state == .idle else { return .none }
            state = .pending
            return .arm
        }
        switch state {
        case .pending:
            state = .idle
            return .disarm
        case .holding:
            state = .idle
            return .end
        case .idle:
            return .none
        }
    }

    /// A click or scroll before the hold begins. It does not stop a recording already in progress.
    mutating func pointer() -> Action {
        guard state == .pending else { return .none }
        state = .idle
        return .disarm
    }

    /// Another key. Before the hold begins this only disarms. After that it cancels the recording.
    mutating func chordFromKey() -> Action {
        switch state {
        case .idle:
            return .none
        case .pending:
            state = .idle
            return .disarm
        case .holding:
            state = .idle
            return .cancelSession
        }
    }
}
