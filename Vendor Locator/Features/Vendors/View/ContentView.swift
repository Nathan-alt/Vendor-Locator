import SwiftUI

/// Presents the vendor list, map, and entry points to search and settings.
struct ContentView: View {
    @StateObject private var model: VendorViewModel
    @State private var showingSearch = false
    @State private var showingSettings = false
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _model = StateObject(wrappedValue: VendorViewModel(repository: dependencies.repository))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mapSection
                vendorList
            }
            .navigationTitle(L10n.appTitle).navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showingSearch) {
                PlaceSearchView(
                    service: dependencies.makePlacesService(),
                    isMock: dependencies.presentation.isMockPlaces,
                    onAdd: model.add
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(tokens: dependencies.tokens, services: dependencies.presentation)
            }
            .task { await model.reload() }
        }
        .appTheme()
    }

    private var mapSection: some View {
        VendorMapSection(
            vendors: model.vendors,
            selectedID: model.selectedID,
            selectionRevision: model.selectionRevision,
            isConfigured: dependencies.presentation.isMapConfigured
        )
    }

    private var vendorList: some View {
        List {
            Section {
                if model.isLoading { DSLoadingView(title: L10n.findingVendors) }
                if let error = model.errorMessage {
                    LoadFailureView(message: error) { Task { await model.reload() } }
                }
                if model.vendors.isEmpty && !model.isLoading && model.errorMessage == nil {
                    EmptyVendorsView()
                }
                ForEach(model.vendors) { vendor in
                    VendorRow(
                        vendor: vendor,
                        isSelected: model.selectedID == vendor.id,
                        onSelect: { model.select(vendor.id) },
                        onFavorite: { model.toggleFavorite(vendor.id) }
                    )
                }
            } header: {
                HStack {
                    Text(L10n.exploreCapeTown)
                    Spacer()
                    Text(L10n.vendorCount(model.vendors.count))
                }
            } footer: {
                Text(L10n.sessionVendorsNotice)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await model.reload() }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel(L10n.settings)
        }
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                Task { await model.reload() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(model.isLoading)
            .accessibilityLabel(L10n.reloadVendors)
            Button {
                showingSearch = true
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .accessibilityLabel(L10n.searchAndAddPlace)
        }
    }
}

#if DEBUG
#Preview("Vendors") {
    ContentView(dependencies: .preview(.populated))
}
#Preview("Empty vendors") {
    ContentView(dependencies: .preview(.empty))
}
#Preview("Vendor failure") {
    ContentView(dependencies: .preview(.failed))
}
#Preview("Loading vendors") {
    ContentView(dependencies: .preview(.loading))
}
#endif
