import Foundation

/// Maps Places failures to localized search or selection guidance.
enum PlaceFailureMessage {

    static func message(_ error: Error, selecting: Bool = false) -> String {
        switch error {
        case PlaceSearchError.configuration:
            return L10n.placesUnavailable
        case PlaceSearchError.missingPlace:
            return L10n.placeLocationMissing
        default:
            return selecting ? L10n.placeAddFailed : L10n.placeSearchFailed
        }
    }
}
