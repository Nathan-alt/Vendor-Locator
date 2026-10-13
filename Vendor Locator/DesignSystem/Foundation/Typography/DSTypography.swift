import SwiftUI

extension DS {
    /// Defines scalable system text styles for common UI roles.
    enum Typography {
        static let title = Font.title2.weight(.semibold)
        static let headline = Font.headline
        static let body = Font.body
        static let detail = Font.subheadline
        static let caption = Font.caption
        static let button = Font.headline
        static let code = Font.system(.body, design: .monospaced)
    }
}
