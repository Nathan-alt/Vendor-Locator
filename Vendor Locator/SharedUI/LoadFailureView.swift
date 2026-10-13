import SwiftUI

/// Feature copy and actions are composed from domain-independent design components.
struct LoadFailureView: View {
    let message: String
    let retry: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.small) {
            DSMessageView(message: message, tone: .error)
            Button(L10n.tryAgain, action: retry).buttonStyle(DSButtonStyle(emphasis: .secondary))
        }
        .accessibilityElement(children: .contain)
    }
}

#Preview("Failure") {
    LoadFailureView(message: L10n.vendorLoadFailed, retry: {}).previewCanvas()
}
