import SwiftUI

/// Applies the shared tint and spacing to progress indicators.
struct DSLoadingStyle: ViewModifier {

    func body(content: Content) -> some View {
        content
            .tint(DS.Colors.accent)
            .padding(.vertical, DS.Spacing.small)
    }
}
