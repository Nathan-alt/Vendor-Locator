import SwiftUI

/// Displays an accessible progress indicator with a localized description.
struct DSLoadingView: View {
    let title: String

    var body: some View {
        ProgressView {
            Text(title).font(DS.Typography.detail)
        }
        .modifier(DSLoadingStyle())
    }
}

#if DEBUG
#Preview("Loading") {
    DSLoadingView(title: L10n.findingVendors).previewCanvas()
}
#endif
