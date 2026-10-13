import CoreGraphics

extension DS {
    /// Defines the shared spacing scale in points.
    enum Spacing {
        static let xs: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }

    /// Defines control target sizes, corner geometry, and map heights.
    enum Layout {
        static let minimumTarget: CGFloat = 44
        static let cornerRadius: CGFloat = 12
        static let mapHeight: CGFloat = 230
        static let accessibleMapHeight: CGFloat = 140
    }
}
