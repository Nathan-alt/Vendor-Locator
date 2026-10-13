import Combine
import Foundation

/// Maintains session vendors, merging remote records with additions and favorites.
@MainActor
final class VendorRepositoryImpl: VendorRepositoryProtocol {
    @Published private(set) var vendors: [Vendor] = []
    var updates: AnyPublisher<[Vendor], Never> { $vendors.eraseToAnyPublisher() }
    private let source: any VendorServiceProtocol
    private var favorites: [String: Bool] = [:]
    private var additions: [Vendor] = []
    private var isReloading = false

    init(source: any VendorServiceProtocol) { self.source = source }

    func reload() async throws(VendorError) {
        guard !isReloading else { return }
        isReloading = true
        defer { isReloading = false }
        let loaded = try await source.load()
        guard !Task.isCancelled else { throw .cancelled }
        var seen = Set<String>()
        // Remote records win duplicate IDs; explicit local favorite choices win both sources.
        vendors = (loaded + additions).filter { seen.insert($0.id).inserted }
            .map {
                var vendor = $0
                vendor.isFavorite = favorites[vendor.id] ?? vendor.isFavorite
                return vendor
            }
    }

    func add(_ vendor: Vendor) {
        guard !vendors.contains(where: { $0.id == vendor.id }) else { return }
        var value = vendor
        value.isFavorite = favorites[value.id] ?? value.isFavorite
        additions.append(value)
        vendors.append(value)
    }

    func toggleFavorite(_ id: String) {
        guard let index = vendors.firstIndex(where: { $0.id == id }) else { return }
        vendors[index].isFavorite.toggle()
        favorites[id] = vendors[index].isFavorite
    }
}
