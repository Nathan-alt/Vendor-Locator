import GoogleMaps
import GooglePlaces
import SwiftUI

/// Initializes SDKs and presents the app with its service dependencies.
@main
@MainActor
struct Vendor_LocatorApp: App {
    private let dependencies: AppDependencies

    init() {
        dependencies = .live()
        if !AppConfiguration.mapsKey.isEmpty { GMSServices.provideAPIKey(AppConfiguration.mapsKey) }
        if !AppConfiguration.placesKey.isEmpty {
            GMSPlacesClient.provideAPIKey(AppConfiguration.placesKey)
        }
    }

    var body: some Scene {
        WindowGroup { ContentView(dependencies: dependencies) }
    }
}
