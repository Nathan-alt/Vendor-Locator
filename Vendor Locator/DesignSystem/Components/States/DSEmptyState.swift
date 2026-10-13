import SwiftUI

/// Combines a symbol, title, and guidance for an empty screen.
struct DSEmptyState: View {
    let title: String
    let message: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.small) {
            Image(systemName: symbol)
                .font(DS.Typography.title)
                .foregroundStyle(DS.Colors.accent)
                .accessibilityHidden(true)

            Text(title)
                .font(DS.Typography.headline)
                .foregroundStyle(DS.Colors.primaryText)

            Text(message)
                .font(DS.Typography.detail)
                .foregroundStyle(DS.Colors.secondaryText)
        }
        .modifier(DSEmptyStateStyle())
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Empty state") {
    DSEmptyState(
        title: L10n.noVendors,
        message: L10n.addFirstVendorHint,
        symbol: "mappin.and.ellipse"
    )
    .previewCanvas()
}
#endif
