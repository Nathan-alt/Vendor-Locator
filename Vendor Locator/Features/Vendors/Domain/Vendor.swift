import Foundation

/// A geographic position with latitude and longitude validation.
struct Coordinate: Equatable {
    let lat: Double
    let lng: Double

    var isValid: Bool {
        lat.isFinite && lng.isFinite && (-90...90).contains(lat) && (-180...180).contains(lng)
    }
}

/// An app-owned vendor record with location, favorite state, and attribution.
struct Vendor: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let coordinate: Coordinate
    var isFavorite: Bool
    let updatedAt: Date
    var attributions: [PlaceAttribution]? = nil
}

/// Provider attribution text and an optional source link.
struct PlaceAttribution: Equatable {
    let text: String
    let url: URL?
}
