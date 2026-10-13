import SwiftUI

/// Applies favorite appearance and hit-target geometry to any control label.
struct DSFavoriteStyle: ViewModifier {
    let isFavorite: Bool

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isFavorite ? DS.Colors.favorite : DS.Colors.secondaryText)
            .frame(minWidth: DS.Layout.minimumTarget, minHeight: DS.Layout.minimumTarget)
            .contentShape(Rectangle())
    }
}
