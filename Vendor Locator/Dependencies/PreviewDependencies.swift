#if DEBUG
import SwiftUI

@MainActor
extension AppDependencies {
    /// Supported vendor-loading scenarios for isolated previews.
    enum PreviewScenario { case populated, empty, failed, loading }

    static func preview(_ scenario: PreviewScenario) -> AppDependencies {
        AppDependencies(
            repository: VendorRepositoryImpl(source: PreviewVendorServiceImpl(scenario: scenario)),
            tokens: PreviewTokenStoreImpl(),
            presentation: ServicePresentation(
                isMockPlaces: true,
                isMapConfigured: false,
                vendorSourceName: L10n.previewService
            ),
            makePlacesService: { MockPlacesServiceImpl() }
        )
    }
}

/// Supplies deterministic vendor responses and failures for previews.
private struct PreviewVendorServiceImpl: VendorServiceProtocol {
    let scenario: AppDependencies.PreviewScenario

    func load() async throws(VendorError) -> [Vendor] {
        switch scenario {
        case .empty: return []
        case .failed: throw VendorError.transport(.http(503))
        case .loading:
            do { try await Task.sleep(nanoseconds: 3_600_000_000_000) } catch { throw .cancelled }
            guard !Task.isCancelled else { throw .cancelled }
            return []
        case .populated:
            return [
                Vendor(
                    id: "preview",
                    name: "Waterfront Kitchen",
                    address: "Cape Town",
                    coordinate: Coordinate(lat: -33.9, lng: 18.4),
                    isFavorite: true,
                    updatedAt: Date(timeIntervalSince1970: 0)
                )
            ]
        }
    }
}

/// Keeps preview tokens in memory without accessing Keychain.
final class PreviewTokenStoreImpl: TokenStoreProtocol {
    private var token: String?

    func read() throws(TokenStoreError) -> String? { token }

    func save(_ token: String) throws(TokenStoreError) { self.token = token }

    func clear() throws(TokenStoreError) { token = nil }
}

/// Shared sample content used by view previews.
enum PreviewFixtures {
    static let vendor = Vendor(
        id: "preview",
        name: "Waterfront Kitchen",
        address: "Cape Town",
        coordinate: Coordinate(lat: -33.9, lng: 18.4),
        isFavorite: true,
        updatedAt: Date(timeIntervalSince1970: 0)
    )
}
#endif
