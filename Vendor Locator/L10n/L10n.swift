import Foundation

/// English copy is maintained in Localizable.xcstrings.
/// Keep dynamic values in complete localized phrases so future translations can reorder them.
enum L10n {

    private static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: "Localizable", bundle: .main, comment: "")
    }

    static var secureStorageFailure: String { string("secureStorageFailure") }
    static var tryAgain: String { string("tryAgain") }
    static var vendorLoadFailed: String { string("vendorLoadFailed") }
    static var vendorResponseInvalid: String { string("vendorResponseInvalid") }
    static var placesUnavailable: String { string("placesUnavailable") }
    static var placeLocationMissing: String { string("placeLocationMissing") }
    static var placeAddFailed: String { string("placeAddFailed") }
    static var placeSearchFailed: String { string("placeSearchFailed") }
    static var mockREST: String { string("mockREST") }
    static var previewService: String { string("previewService") }
    static var demoPlacesHint: String { string("demoPlacesHint") }
    static var addingPlace: String { string("addingPlace") }
    static var searching: String { string("searching") }
    static var noPlacesFound: String { string("noPlacesFound") }
    static var googleMaps: String { string("googleMaps") }
    static var placeSearchPrompt: String { string("placeSearchPrompt") }
    static var addPlace: String { string("addPlace") }
    static var cancel: String { string("cancel") }
    static var addressUnavailable: String { string("addressUnavailable") }
    static var selectedOnMap: String { string("selectedOnMap") }
    static var findingVendors: String { string("findingVendors") }
    static var exploreCapeTown: String { string("exploreCapeTown") }
    static var sessionVendorsNotice: String { string("sessionVendorsNotice") }
    static var appTitle: String { string("appTitle") }
    static var settings: String { string("settings") }
    static var reloadVendors: String { string("reloadVendors") }
    static var searchAndAddPlace: String { string("searchAndAddPlace") }
    static var noVendors: String { string("noVendors") }
    static var addFirstVendorHint: String { string("addFirstVendorHint") }
    static var vendorMap: String { string("vendorMap") }
    static var mapSetupRequired: String { string("mapSetupRequired") }
    static var nearbyHeadline: String { string("nearbyHeadline") }
    static var mapSetupShort: String { string("mapSetupShort") }
    static var mapSetupDetail: String { string("mapSetupDetail") }
    static var sessionToken: String { string("sessionToken") }
    static var saveSecurely: String { string("saveSecurely") }
    static var tokenSaved: String { string("tokenSaved") }
    static var revealToken: String { string("revealToken") }
    static var noToken: String { string("noToken") }
    static var tokenRevealed: String { string("tokenRevealed") }
    static var hideToken: String { string("hideToken") }
    static var clearToken: String { string("clearToken") }
    static var tokenCleared: String { string("tokenCleared") }
    static var session: String { string("session") }
    static var secureStorageNotice: String { string("secureStorageNotice") }
    static var services: String { string("services") }
    static var vendors: String { string("vendors") }
    static var places: String { string("places") }
    static var mock: String { string("mock") }
    static var google: String { string("google") }
    static var mapKey: String { string("mapKey") }
    static var configured: String { string("configured") }
    static var notConfigured: String { string("notConfigured") }
    static var done: String { string("done") }

    static func vendorCount(_ count: Int) -> String {
        String.localizedStringWithFormat(string("vendorCount"), Int64(count))
    }

    static func favoriteAction(name: String, isFavorite: Bool) -> String {
        String.localizedStringWithFormat(
            string(isFavorite ? "unfavoriteVendor" : "favoriteVendor"),
            name
        )
    }

}
