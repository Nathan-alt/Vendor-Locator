import SwiftUI

/// Distinguishes informational and error message styling.
enum DSMessageTone { case information, error }

/// The message layout and icon remain the component's responsibility.
struct DSMessageStyle: ViewModifier {
    var tone: DSMessageTone = .information

    func body(content: Content) -> some View {
        content
            .foregroundStyle(tone == .error ? DS.Colors.error : DS.Colors.secondaryText)
            .padding(.vertical, DS.Spacing.xs)
    }
}
