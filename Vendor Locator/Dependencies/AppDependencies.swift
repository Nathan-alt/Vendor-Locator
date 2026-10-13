import Foundation

/// Display-only service labels and configuration flags for the UI.
struct ServicePresentation {
    let isMockPlaces: Bool
    let isMapConfigured: Bool
    let vendorSourceName: String
}

/// The only place that selects concrete implementations and their lifetimes.
@MainActor
struct AppDependencies {
    let repository: any VendorRepositoryProtocol
    let tokens: any TokenStoreProtocol
    let presentation: ServicePresentation
    let makePlacesService: @MainActor () -> any PlacesServiceProtocol

    static func live() -> AppDependencies {
        let tokens = TokenStoreImpl()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DemoVendorURLProtocol.self]
        let executor = NetworkExecutorImpl(session: URLSession(configuration: configuration))
        let vendorService = VendorServiceImpl(
            executor: executor,
            tokens: tokens,
            endpoint: Constants.Network.Vendors.demoEndpoint,
            parser: DataParserImpl()
        )
        let mockPlaces = AppConfiguration.mockPlaces
        let placesConfigured = !AppConfiguration.placesKey.isEmpty
        return AppDependencies(
            repository: VendorRepositoryImpl(source: vendorService),
            tokens: tokens,
            presentation: ServicePresentation(
                isMockPlaces: mockPlaces,
                isMapConfigured: !AppConfiguration.mapsKey.isEmpty,
                vendorSourceName: L10n.mockREST
            ),
            makePlacesService: {
                if mockPlaces { return MockPlacesServiceImpl() }
                return PlacesServiceImpl(isConfigured: placesConfigured)
            }
        )
    }
}
