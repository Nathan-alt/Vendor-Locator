import SwiftUI

/// Shows the vendor map or guidance when its key is not configured.
struct VendorMapSection: View {
    let vendors: [Vendor]
    let selectedID: String?
    let selectionRevision: Int
    let isConfigured: Bool
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if isConfigured {
            GoogleMapView(
                vendors: vendors,
                selectedID: selectedID,
                selectionRevision: selectionRevision
            )
            .frame(
                height: dynamicTypeSize.isAccessibilitySize
                    ? DS.Layout.accessibleMapHeight : DS.Layout.mapHeight
            )
            .accessibilityLabel(L10n.vendorMap)
        } else {
            VStack(spacing: DS.Spacing.medium) {
                Image(systemName: "map.fill")
                    .font(dynamicTypeSize.isAccessibilitySize ? DS.Typography.body : .largeTitle)
                    .foregroundStyle(DS.Colors.accent)
                Text(
                    dynamicTypeSize.isAccessibilitySize
                        ? L10n.mapSetupRequired : L10n.nearbyHeadline
                )
                .font(DS.Typography.headline)
                Text(dynamicTypeSize.isAccessibilitySize ? L10n.mapSetupShort : L10n.mapSetupDetail)
                    .font(DS.Typography.detail).foregroundStyle(DS.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(DS.Spacing.extraLarge).frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .background(DS.Colors.surface)
        }
    }
}

#if DEBUG
#Preview("Map setup") {
    VendorMapSection(
        vendors: [PreviewFixtures.vendor],
        selectedID: nil,
        selectionRevision: 0,
        isConfigured: false
    )
    .appTheme()
}
#Preview("Map setup · Accessibility") {
    VendorMapSection(vendors: [], selectedID: nil, selectionRevision: 0, isConfigured: false)
        .appTheme().environment(\.dynamicTypeSize, .accessibility3)
}
#endif
