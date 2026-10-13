import Foundation

/// Loads vendor records through a typed feature boundary.
protocol VendorServiceProtocol {

    func load() async throws(VendorError) -> [Vendor]
}
