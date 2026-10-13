import Foundation
import GooglePlaces

/// Adapts Google Places callbacks to typed asynchronous search operations.
@MainActor
final class PlacesServiceImpl: PlacesServiceProtocol {
    private let isConfigured: Bool

    init(isConfigured: Bool) { self.isConfigured = isConfigured }
    private var sessionToken = GMSAutocompleteSessionToken()

    func suggestions(for query: String) async throws(PlaceSearchError) -> [PlaceSuggestion] {
        guard !Task.isCancelled else { throw .cancelled }
        guard isConfigured else { throw PlaceSearchError.configuration }
        let filter = GMSAutocompleteFilter()
        filter.countries = ["ZA"]
        do {
            let result = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<[PlaceSuggestion], Error>) in
                GMSPlacesClient.shared()
                    .findAutocompletePredictions(
                        fromQuery: query,
                        filter: filter,
                        sessionToken: sessionToken
                    ) { results, error in
                        if let error {
                            continuation.resume(throwing: error)
                            return
                        }
                        continuation.resume(
                            returning: (results ?? [])
                                .map {
                                    PlaceSuggestion(
                                        id: $0.placeID,
                                        title: $0.attributedPrimaryText.string,
                                        subtitle: $0.attributedSecondaryText?.string ?? ""
                                    )
                                }
                        )
                    }
            }
            guard !Task.isCancelled else { throw PlaceSearchError.cancelled }
            return result
        } catch { throw PlaceSearchError.encapsulating(error) }
    }

    func details(for id: String) async throws(PlaceSearchError) -> Vendor {
        guard !Task.isCancelled else { throw .cancelled }
        guard isConfigured else { throw PlaceSearchError.configuration }
        defer { sessionToken = GMSAutocompleteSessionToken() }
        do {
            let result = try await withCheckedThrowingContinuation {
                (continuation: CheckedContinuation<Vendor, Error>) in
                let request = GMSFetchPlaceRequest(
                    placeID: id,
                    placeProperties: [
                        GMSPlaceProperty.name, .formattedAddress, .coordinate, .placeID,
                    ]
                    .map(\.rawValue),
                    sessionToken: sessionToken
                )
                GMSPlacesClient.shared()
                    .fetchPlace(with: request) { place, error in
                        if let error {
                            continuation.resume(throwing: error)
                            return
                        }
                        guard let place, let name = place.name,
                            CLLocationCoordinate2DIsValid(place.coordinate)
                        else {
                            continuation.resume(throwing: PlaceSearchError.missingPlace)
                            return
                        }
                        var attributions: [PlaceAttribution] = []
                        if let text = place.attributions {
                            text.enumerateAttributes(in: NSRange(location: 0, length: text.length))
                            { attributes, range, _ in
                                let link =
                                    attributes[.link] as? URL
                                    ?? (attributes[.link] as? String).flatMap(URL.init(string:))
                                attributions.append(
                                    PlaceAttribution(
                                        text: text.attributedSubstring(from: range).string,
                                        url: link
                                    )
                                )
                            }
                        }
                        continuation.resume(
                            returning: Vendor(
                                id: "place:\(id)",
                                name: name,
                                address: place.formattedAddress ?? L10n.addressUnavailable,
                                coordinate: Coordinate(
                                    lat: place.coordinate.latitude,
                                    lng: place.coordinate.longitude
                                ),
                                isFavorite: false,
                                updatedAt: Date(),
                                attributions: attributions
                            )
                        )
                    }
            }
            guard !Task.isCancelled else { throw PlaceSearchError.cancelled }
            return result
        } catch { throw PlaceSearchError.encapsulating(error) }
    }
}
