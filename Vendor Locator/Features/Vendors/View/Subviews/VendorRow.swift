import SwiftUI

/// Displays a vendor with map selection, favorite action, and attribution.
struct VendorRow: View {
    let vendor: Vendor
    let isSelected: Bool
    let onSelect: () -> Void
    let onFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.small) {
            HStack(spacing: DS.Spacing.medium) {
                Button(action: onSelect) {
                    HStack(spacing: DS.Spacing.medium) {
                        Image(systemName: "fork.knife.circle.fill").font(DS.Typography.title)
                            .foregroundStyle(DS.Colors.accent)
                        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                            Text(vendor.name).font(DS.Typography.headline)
                                .foregroundStyle(DS.Colors.primaryText)
                            Text(vendor.address).font(DS.Typography.detail)
                                .foregroundStyle(DS.Colors.secondaryText)
                            if isSelected {
                                Label(L10n.selectedOnMap, systemImage: "mappin")
                                    .font(DS.Typography.caption).foregroundStyle(DS.Colors.accent)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                DSFavoriteButton(
                    isFavorite: vendor.isFavorite,
                    accessibilityLabel: L10n.favoriteAction(
                        name: vendor.name,
                        isFavorite: vendor.isFavorite
                    ),
                    action: onFavorite
                )
            }
            .padding(.vertical, DS.Spacing.small)
            if let items = vendor.attributions, !items.isEmpty {
                Text(
                    items.reduce(into: AttributedString()) { text, item in
                        var part = AttributedString(item.text)
                        part.link = item.url
                        text.append(part)
                    }
                )
                .font(DS.Typography.caption)
            }
        }
    }
}

#if DEBUG
#Preview("Vendor row · Selected") {
    List {
        VendorRow(vendor: PreviewFixtures.vendor, isSelected: true, onSelect: {}, onFavorite: {})
    }
    .appTheme()
}
#Preview("Vendor row · Accessibility") {
    List {
        VendorRow(vendor: PreviewFixtures.vendor, isSelected: false, onSelect: {}, onFavorite: {})
    }
    .appTheme().environment(\.dynamicTypeSize, .accessibility3)
}
#endif
