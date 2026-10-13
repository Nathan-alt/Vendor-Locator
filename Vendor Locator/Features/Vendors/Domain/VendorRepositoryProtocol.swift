import Combine

/// Owns the session's vendor collection independently of any screen.
@MainActor
protocol VendorRepositoryProtocol: AnyObject {
    var vendors: [Vendor] { get }
    var updates: AnyPublisher<[Vendor], Never> { get }

    func reload() async throws(VendorError)

    func add(_ vendor: Vendor)

    func toggleFavorite(_ id: String)
}
