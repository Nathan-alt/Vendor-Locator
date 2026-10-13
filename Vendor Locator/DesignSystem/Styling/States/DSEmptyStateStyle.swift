import SwiftUI

/// Applies wrapping and vertical spacing to empty-state content.
struct DSEmptyStateStyle: ViewModifier {

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, DS.Spacing.small)
    }
}
