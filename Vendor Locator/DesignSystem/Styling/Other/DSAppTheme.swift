import SwiftUI

/// Applies the shared accent color and default typography.
struct DSAppTheme: ViewModifier {

    func body(content: Content) -> some View {
        content.tint(DS.Colors.accent).font(DS.Typography.body)
    }
}

extension View {
    /// Apply at each navigation root, including independently presented sheets.

    func appTheme() -> some View { modifier(DSAppTheme()) }
}
