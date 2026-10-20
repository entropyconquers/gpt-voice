import AppKit
import SwiftUI

/// Type roles, in two families with distinct jobs:
/// - FT Regola Neue (display): page titles, section headings and the GPT Voice wordmark. Only its three
///   shipped weights are used, so no weight is ever synthesized.
/// - San Francisco (system): everything people read or operate, such as rows, body, details, controls,
///   keycaps, captions and timers.
/// Numbers that change in place (timers) add tabular figures with `.monospacedDigit()` at the call site.
enum AppType {
    static let regular = "FTRegolaNeue-Regular"
    static let medium = "FTRegolaNeue-Medium"
    static let semibold = "FTRegolaNeue-Semibold"

    // MARK: Display (FT Regola Neue)

    /// Page and onboarding titles.
    static let title = Font.custom(semibold, size: 26)
    /// Section headings and the sidebar wordmark.
    static let heading = Font.custom(semibold, size: 15)
    /// The GPT Voice wordmark inline with other text (About row).
    static let brand = Font.custom(medium, size: 14)

    // MARK: Reading and controls (San Francisco)

    /// Row titles and selected sidebar items.
    static let rowTitle = Font.system(size: 14, weight: .medium)
    static let body = Font.system(size: 14, weight: .regular)
    static let detail = Font.system(size: 13, weight: .regular)
    /// Small labels, step counts, disclosure labels.
    static let caption = Font.system(size: 12, weight: .medium)
    static let control = Font.system(size: 13.5, weight: .medium)
    static let controlSmall = Font.system(size: 12.5, weight: .medium)
    static let keycap = Font.system(size: 13, weight: .medium)
    static let keycapLarge = Font.system(size: 20, weight: .medium)
    /// Timers: tabular figures applied by the caller.
    static let timer = Font.system(size: 12.5, weight: .medium)

    /// Title tracking, as in the reference type scale (tight at large sizes).
    static let titleTracking: CGFloat = -0.4

    /// AppKit counterpart of `controlSmall`, for custom-painted controls.
    static var nsControlSmall: NSFont { .systemFont(ofSize: 12.5, weight: .medium) }
}
