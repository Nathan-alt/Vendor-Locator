import Foundation

/// Provides local sample places and deterministic search failures.
@MainActor
struct MockPlacesServiceImpl: PlacesServiceProtocol {
    private let places = [
        Vendor(
            id: "place:demo-waterfront",
            name: "Waterfront Kitchen",
            address: "Dock Rd, V&A Waterfront, Cape Town",
            coordinate: Coordinate(lat: -33.9036, lng: 18.4207),
            isFavorite: false,
            updatedAt: Date(timeIntervalSince1970: 1748779200)
        ),
        Vendor(
            id: "place:demo-observatory",
            name: "Observatory Bakery",
            address: "Lower Main Rd, Observatory, Cape Town",
            coordinate: Coordinate(lat: -33.9382, lng: 18.4685),
            isFavorite: false,
            updatedAt: Date(timeIntervalSince1970: 1748779200)
        ),
    ]

    func suggestions(for query: String) async throws(PlaceSearchError) -> [PlaceSuggestion] {
        do { try await Task.sleep(nanoseconds: 250_000_000) } catch { throw .cancelled }
        if query.lowercased() == "error" { throw PlaceSearchError.unavailable }
        return places.filter { "\($0.name) \($0.address)".localizedCaseInsensitiveContains(query) }
            .map { PlaceSuggestion(id: $0.id, title: $0.name, subtitle: $0.address) }
    }

    func details(for id: String) async throws(PlaceSearchError) -> Vendor {
        guard let vendor = places.first(where: { $0.id == id }) else {
            throw PlaceSearchError.missingPlace
        }
        return vendor
    }
}
