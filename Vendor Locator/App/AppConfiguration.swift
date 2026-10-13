import Foundation

/// Reads environment-sensitive settings from the app bundle.
enum AppConfiguration {

    static func value(_ key: String) -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
        return value.hasPrefix("$(") ? "" : value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    static var mapsKey: String { value("GoogleMapsAPIKey") }
    static var placesKey: String { value("GooglePlacesAPIKey") }
    static var mockPlaces: Bool { value("UseMockPlaces") != "NO" }
}
