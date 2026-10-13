import SwiftUI

/// Explains how to add a vendor when the collection is empty.
struct EmptyVendorsView: View {
    var body: some View {
        DSEmptyState(
            title: L10n.noVendors,
            message: L10n.addFirstVendorHint,
            symbol: "mappin.and.ellipse"
        )
    }
}

#Preview("Empty") {
    EmptyVendorsView().previewCanvas()
}
