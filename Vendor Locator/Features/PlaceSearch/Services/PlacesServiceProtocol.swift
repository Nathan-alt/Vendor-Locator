import Foundation

/// A display-ready autocomplete result identified by its place ID.
struct PlaceSuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
}

/// Represents safe search failures without retaining provider error details.
enum PlaceSearchError: Error, Equatable {
    case missingPlace
    case configuration
    case cancelled
    case unavailable

    static func encapsulating(_ error: Error) -> PlaceSearchError {
        if Task.isCancelled || error is CancellationError
            || (error as? URLError)?.code == .cancelled
        {
            return .cancelled
        }
        return (error as? PlaceSearchError) ?? .unavailable
    }
}

/// Defines typed autocomplete and place-detail operations.
@MainActor
protocol PlacesServiceProtocol {

    func suggestions(for query: String) async throws(PlaceSearchError) -> [PlaceSuggestion]

    func details(for id: String) async throws(PlaceSearchError) -> Vendor
}
