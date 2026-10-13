import SwiftUI

/// Displays a favorite action using the shared icon style and minimum touch target.
struct DSFavoriteButton: View {
    let isFavorite: Bool
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .modifier(DSFavoriteStyle(isFavorite: isFavorite))
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(accessibilityLabel)
    }
}

#if DEBUG
#Preview("Favorite · On") {
    DSFavoriteButton(
        isFavorite: true,
        accessibilityLabel: L10n.favoriteAction(name: "Sample", isFavorite: true),
        action: {}
    )
    .previewCanvas()
}

#Preview("Favorite · Off") {
    DSFavoriteButton(
        isFavorite: false,
        accessibilityLabel: L10n.favoriteAction(name: "Sample", isFavorite: false),
        action: {}
    )
    .previewCanvas()
}
#endif
