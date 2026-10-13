import GoogleMaps
import SwiftUI

/// Bridges the Google map into SwiftUI with vendor markers and camera selection.
struct GoogleMapView: UIViewRepresentable {
    let vendors: [Vendor]
    let selectedID: String?
    let selectionRevision: Int
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition(latitude: -33.918861, longitude: 18.4233, zoom: 12)
        let map = GMSMapView(options: options)
        map.settings.compassButton = true
        map.isMyLocationEnabled = false
        return map
    }

    func updateUIView(_ map: GMSMapView, context: Context) {
        let coordinator = context.coordinator
        let ids = Set(vendors.map(\.id))
        for id in Array(coordinator.markers.keys) where !ids.contains(id) {
            coordinator.markers.removeValue(forKey: id)?.map = nil
        }
        for vendor in vendors {
            let marker = coordinator.markers[vendor.id] ?? GMSMarker()
            marker.position = CLLocationCoordinate2D(
                latitude: vendor.coordinate.lat,
                longitude: vendor.coordinate.lng
            )
            marker.title = vendor.name
            marker.snippet = vendor.address
            marker.icon = GMSMarker.markerImage(
                with: vendor.id == selectedID ? DS.Palette.selectedMarker : DS.Palette.accent
            )
            marker.map = map
            coordinator.markers[vendor.id] = marker
        }
        if coordinator.dark != (colorScheme == .dark) {
            coordinator.dark = colorScheme == .dark
            map.mapStyle = colorScheme == .dark ? try? GMSMapStyle(jsonString: Self.darkStyle) : nil
        }
        if let selectedID, let marker = coordinator.markers[selectedID],
            coordinator.selectionRevision != selectionRevision
        {
            map.animate(to: GMSCameraPosition(target: marker.position, zoom: 15))
            map.selectedMarker = marker
            coordinator.selectionRevision = selectionRevision
            coordinator.didFit = true
        } else if !coordinator.didFit, let first = vendors.first {
            var bounds = GMSCoordinateBounds(
                coordinate: CLLocationCoordinate2D(
                    latitude: first.coordinate.lat,
                    longitude: first.coordinate.lng
                ),
                coordinate: CLLocationCoordinate2D(
                    latitude: first.coordinate.lat,
                    longitude: first.coordinate.lng
                )
            )
            for marker in coordinator.markers.values {
                bounds = bounds.includingCoordinate(marker.position)
            }
            map.moveCamera(GMSCameraUpdate.fit(bounds, withPadding: 45))
            coordinator.didFit = true
        }
    }
    /// Retains map markers and camera state across SwiftUI updates.
    final class Coordinator {
        var markers: [String: GMSMarker] = [:]
        var selectionRevision = -1
        var didFit = false
        var dark: Bool?
    }
    private static let darkStyle = """
        [{"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
         {"elementType":"labels.text.fill","stylers":[{"color":"#d7dce2"}]},
         {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
         {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
         {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]}]
        """
}

#if DEBUG
/// Google requires SDK initialization even in the preview process.
private extension GoogleMapView {

    static func configurePreview() -> Bool {
        guard !AppConfiguration.mapsKey.isEmpty else { return false }
        return GMSServices.provideAPIKey(AppConfiguration.mapsKey)
    }
}

#Preview("Google map · Configured key required") {
    if GoogleMapView.configurePreview() {
        GoogleMapView(
            vendors: [PreviewFixtures.vendor],
            selectedID: PreviewFixtures.vendor.id,
            selectionRevision: 1
        )
        .frame(height: DS.Layout.mapHeight)
    } else {
        DSMessageView(message: L10n.mapSetupShort).padding().appTheme()
    }
}
#endif
