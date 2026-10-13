import Foundation

/// The REST schema is deliberately independent of the app's vendor model.
struct VendorDTO: Decodable {
    /// Decodes the coordinate fields supplied by the vendor API.
    struct CoordinateDTO: Decodable {
        let lat: Double
        let lng: Double
    }
    /// Decodes provider attribution text and its optional URL.
    struct AttributionDTO: Decodable {
        let text: String
        let url: URL?
    }
    let id: String
    let name: String
    let address: String
    let coordinate: CoordinateDTO
    let isFavorite: Bool
    let updatedAt: Date
    let attributions: [AttributionDTO]?

    func vendor() throws(VendorError) -> Vendor {
        let location = Coordinate(lat: coordinate.lat, lng: coordinate.lng)
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            location.isValid
        else { throw VendorError.invalidResponse }
        return Vendor(
            id: id,
            name: name,
            address: address,
            coordinate: location,
            isFavorite: isFavorite,
            updatedAt: updatedAt,
            attributions: attributions?.map { PlaceAttribution(text: $0.text, url: $0.url) }
        )
    }
}
