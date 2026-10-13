import SwiftUI

/// Styles primary and secondary actions with role and interaction feedback.
struct DSButtonStyle: ButtonStyle {
    /// Selects a filled primary or tinted secondary button appearance.
    enum Emphasis { case primary, secondary }
    var emphasis: Emphasis = .primary
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let accent = configuration.role == .destructive ? DS.Colors.error : DS.Colors.accent
        configuration.label
            .font(DS.Typography.button)
            .padding(.horizontal, DS.Spacing.large)
            .padding(.vertical, DS.Spacing.small)
            .frame(minHeight: DS.Layout.minimumTarget)
            .foregroundStyle(emphasis == .primary ? DS.Colors.onAccent : accent)
            .background(emphasis == .primary ? accent : accent.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.75 : 1) : 0.45)
    }
}

#if DEBUG
#Preview("Button styles") {
    VStack(spacing: DS.Spacing.medium) {
        Button(L10n.tryAgain, action: {}).buttonStyle(DSButtonStyle())
        Button(L10n.tryAgain, action: {}).buttonStyle(DSButtonStyle(emphasis: .secondary))
        Button(L10n.tryAgain, action: {}).buttonStyle(DSButtonStyle()).disabled(true)
    }
    .previewCanvas()
}
#endif
