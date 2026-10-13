import SwiftUI

/// Presents place search and owns the search view model lifecycle.
struct PlaceSearchView: View {
    @StateObject private var model: PlaceSearchViewModel
    let isMock: Bool
    let onAdd: (Vendor) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var detailTask: Task<Void, Never>?

    init(
        service: any PlacesServiceProtocol,
        isMock: Bool,
        initialQuery: String = "",
        onAdd: @escaping (Vendor) -> Void
    ) {
        _model = StateObject(wrappedValue: PlaceSearchViewModel(service: service))
        _query = State(initialValue: initialQuery)
        self.isMock = isMock
        self.onAdd = onAdd
    }

    var body: some View {
        NavigationStack {
            List {
                searchResults
            }
            .safeAreaInset(edge: .bottom) {
                if !isMock {
                    Text(L10n.googleMaps).font(DS.Typography.detail)
                        .foregroundStyle(DS.Colors.primaryText)
                        .padding(DS.Spacing.medium).frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                }
            }
            .searchable(text: $query, prompt: L10n.placeSearchPrompt)
            .navigationTitle(L10n.addPlace).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button(L10n.cancel) { dismiss() } }
            }
            .task(id: query) { await model.search(query) }
            .appTheme()
            .onDisappear {
                detailTask?.cancel()
                model.deactivate()
            }
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        if isMock { DSMessageView(message: L10n.demoPlacesHint) }
        if model.isSearching || model.isAdding {
            DSLoadingView(title: model.isAdding ? L10n.addingPlace : L10n.searching)
        }
        if let error = model.errorMessage { DSMessageView(message: error, tone: .error) }
        ForEach(model.results) { result in
            Button {
                detailTask = Task { @MainActor in
                    guard let vendor = await model.select(result.id), !Task.isCancelled else {
                        return
                    }
                    onAdd(vendor)
                    dismiss()
                }
            } label: {
                PlaceSuggestionRow(suggestion: result)
            }
            .disabled(model.isAdding)
        }
        if model.isEmpty && model.errorMessage == nil {
            DSMessageView(message: L10n.noPlacesFound)
        }
    }
}

#if DEBUG
#Preview("Search · Idle") {
    PlaceSearchView(service: MockPlacesServiceImpl(), isMock: true, onAdd: { _ in })
}
#Preview("Search · Results") {
    PlaceSearchView(
        service: MockPlacesServiceImpl(),
        isMock: true,
        initialQuery: "Waterfront",
        onAdd: { _ in }
    )
}
#Preview("Search · Empty") {
    PlaceSearchView(
        service: MockPlacesServiceImpl(),
        isMock: true,
        initialQuery: "No matching place",
        onAdd: { _ in }
    )
}
#Preview("Search · Error") {
    PlaceSearchView(
        service: MockPlacesServiceImpl(),
        isMock: true,
        initialQuery: "error",
        onAdd: { _ in }
    )
}
#endif
