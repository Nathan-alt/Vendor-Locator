import XCTest

@testable import Vendor_Locator

final class Vendor_LocatorTests: XCTestCase {
    @MainActor

    func testReloadPreservesFavoritesAndAddedPlacesWithoutDuplicates() async {
        let original = Vendor(
            id: "original",
            name: "Original",
            address: "Cape Town",
            coordinate: Coordinate(lat: -33.9, lng: 18.4),
            isFavorite: false,
            updatedAt: Date()
        )
        let addition = Vendor(
            id: "place:added",
            name: "Added",
            address: "Cape Town",
            coordinate: Coordinate(lat: -33.91, lng: 18.41),
            isFavorite: false,
            updatedAt: Date()
        )
        let service = StubVendorServiceImpl(vendors: [original])
        let model = VendorViewModel(repository: VendorRepositoryImpl(source: service))
        await model.reload()
        model.toggleFavorite(original.id)
        model.add(addition)
        model.add(addition)
        model.toggleFavorite(addition.id)
        await model.reload()
        XCTAssertEqual(model.vendors.map(\.id), [original.id, addition.id])
        XCTAssertTrue(model.vendors.allSatisfy(\.isFavorite))
        XCTAssertEqual(model.selectedID, addition.id)
        // When the server later includes the added place, it still appears only once.
        service.vendors = [original, addition, original]
        await model.reload()
        XCTAssertEqual(model.vendors.map(\.id), [original.id, addition.id])
        XCTAssertTrue(model.vendors.allSatisfy(\.isFavorite))
    }
}

@MainActor
private final class StubVendorServiceImpl: VendorServiceProtocol {
    var vendors: [Vendor]

    init(vendors: [Vendor]) { self.vendors = vendors }

    func load() async throws(VendorError) -> [Vendor] { vendors }
}
