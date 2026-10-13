#if DEBUG
import SwiftUI

/// Gives small component previews room to breathe without forcing appearance.
/// Uses ViewModifier so it also works with the app's iOS 16 deployment target.
struct PreviewCanvasModifier: ViewModifier {

    func body(content: Content) -> some View {
        content
            .padding(DS.Spacing.extraLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.background)
            .appTheme()
    }
}

extension View {

    func previewCanvas() -> some View { modifier(PreviewCanvasModifier()) }
}
#endif
