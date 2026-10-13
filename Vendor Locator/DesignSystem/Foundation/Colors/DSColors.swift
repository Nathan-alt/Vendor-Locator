import SwiftUI
import UIKit

extension DS {
    /// Provides adaptive UIKit colors shared with platform adapters.
    enum Palette {
        static let accent = UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.40, green: 0.85, blue: 0.80, alpha: 1)
                : UIColor(red: 0.00, green: 0.38, blue: 0.40, alpha: 1)
        }

        static let onAccent = UIColor { traits in
            traits.userInterfaceStyle == .dark ? .black : .white
        }

        static let selectedMarker = UIColor.systemOrange
        static let favorite = UIColor.systemPink
    }

    /// Exposes semantic SwiftUI colors for content and surfaces.
    enum Colors {
        static let accent = Color(uiColor: Palette.accent)
        static let onAccent = Color(uiColor: Palette.onAccent)
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let surface = Color(uiColor: .secondarySystemBackground)
        static let background = Color(uiColor: .systemGroupedBackground)
        static let error = Color(uiColor: .systemRed)
        static let favorite = Color(uiColor: Palette.favorite)
    }
}
