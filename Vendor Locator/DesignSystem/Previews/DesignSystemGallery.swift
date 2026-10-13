#if DEBUG
import SwiftUI

/// Developer-only specimen copy intentionally stays outside the localization catalog.
private struct DesignSystemGallery: View {
    @State private var isFavorite = false

    var body: some View {
        TabView {
            galleryTab(title: "Buttons") {
                buttons
            }
            .tabItem {
                Label("Buttons", systemImage: "rectangle.and.hand.point.up.left")
            }

            galleryTab(title: "Loaders") {
                loaders
            }
            .tabItem {
                Label("Loaders", systemImage: "progress.indicator")
            }

            galleryTab(title: "Text") {
                text
            }
            .tabItem {
                Label("Text", systemImage: "textformat")
            }

            galleryTab(title: "Other") {
                other
            }
            .tabItem {
                Label("Other", systemImage: "square.grid.2x2")
            }
        }
        .appTheme()
    }

    private var buttons: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.medium) {
            Button {
            } label: {
                Text(verbatim: "Primary action")
            }
            .buttonStyle(DSButtonStyle())

            Button {
            } label: {
                Text(verbatim: "Secondary action")
            }
            .buttonStyle(DSButtonStyle(emphasis: .secondary))

            Button {
            } label: {
                Text(verbatim: "Disabled action")
            }
            .buttonStyle(DSButtonStyle())
            .disabled(true)

            Button(role: .destructive, action: {}) {
                Text(verbatim: "Destructive action")
            }
            .buttonStyle(DSButtonStyle(emphasis: .secondary))

            DSFavoriteButton(
                isFavorite: isFavorite,
                accessibilityLabel: isFavorite
                    ? "Unfavorite sample vendor" : "Favorite sample vendor"
            ) {
                isFavorite.toggle()
            }
        }
    }

    private var loaders: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.medium) {
            DSLoadingView(title: "Loading sample content…")
        }
    }

    private var text: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.extraLarge) {
            VStack(alignment: .leading, spacing: DS.Spacing.small) {
                Text(verbatim: "Title").font(DS.Typography.title)
                Text(verbatim: "Headline").font(DS.Typography.headline)
                Text(verbatim: "Body text adapts to your preferred reading size.")
                    .font(DS.Typography.body)
                Text(verbatim: "Supporting details")
                    .font(DS.Typography.detail)
                    .foregroundStyle(DS.Colors.secondaryText)
                Text(verbatim: "Caption and attribution").font(DS.Typography.caption)
                Text(verbatim: "Monospaced code").font(DS.Typography.code)
            }

            DSMessageView(
                message: "Helpful information remains readable at larger text sizes."
            )

            DSMessageView(
                message: "An operation failed. An icon and message explain the state.",
                tone: .error
            )
        }
    }

    private var other: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.extraLarge) {
            DSEmptyState(
                title: "Nothing here yet",
                message: "A useful next step belongs here.",
                symbol: "mappin.and.ellipse"
            )

            colorSwatches
        }
    }

    private var colorSwatches: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.small) {
            Text(verbatim: "Semantic colors").font(DS.Typography.headline)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 72), spacing: DS.Spacing.medium)],
                alignment: .leading,
                spacing: DS.Spacing.medium
            ) {
                colorSwatch("Accent", color: DS.Colors.accent)
                colorSwatch("Favorite", color: DS.Colors.favorite)
                colorSwatch("Error", color: DS.Colors.error)
                colorSwatch("Surface", color: DS.Colors.surface)
            }
        }
    }

    private func galleryTab<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.extraLarge) {
                Text(verbatim: title).font(DS.Typography.title)
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DS.Spacing.extraLarge)
        }
        .background(DS.Colors.background)
    }

    private func colorSwatch(_ title: String, color: Color) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                .fill(color)
                .frame(width: 48, height: 48)

            Text(verbatim: title)
                .font(DS.Typography.caption)
                .foregroundStyle(DS.Colors.secondaryText)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Design system") {
    DesignSystemGallery()
}
#Preview("Design system · Accessibility") {
    DesignSystemGallery().environment(\.dynamicTypeSize, .accessibility3)
}
#endif
