import SwiftUI

/// Displays the title and address of a suggested place.
struct PlaceSuggestionRow: View {
    let suggestion: PlaceSuggestion
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text(suggestion.title).foregroundStyle(DS.Colors.primaryText)
            Text(suggestion.subtitle).font(DS.Typography.detail)
                .foregroundStyle(DS.Colors.secondaryText)
        }
    }
}

#Preview {
    PlaceSuggestionRow(
        suggestion: PlaceSuggestion(id: "demo", title: "Waterfront Kitchen", subtitle: "Cape Town")
    )
}
