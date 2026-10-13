import SwiftUI

/// Presents informational or error copy with a supporting symbol.
struct DSMessageView: View {
    let message: String
    var tone: DSMessageTone = .information

    var body: some View {
        Label {
            Text(message)
                .font(DS.Typography.detail)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: tone == .error ? "exclamationmark.circle" : "info.circle")
                .accessibilityHidden(true)
        }
        .modifier(DSMessageStyle(tone: tone))
        .accessibilityElement(children: .combine)
    }
}

#if DEBUG
#Preview("Information") {
    DSMessageView(message: L10n.demoPlacesHint).previewCanvas()
}

#Preview("Error") {
    DSMessageView(message: L10n.vendorLoadFailed, tone: .error).previewCanvas()
}
#endif
