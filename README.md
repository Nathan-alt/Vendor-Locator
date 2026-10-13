# Vendor Locator

A focused SwiftUI take-home app for browsing Cape Town vendors, selecting Google Maps markers, adding Places search results, and storing a session token in Keychain.

## Run locally

1. Open `Vendor Locator.xcodeproj` in **Xcode 26.2 or later**. The supplied project format uses Xcode's synchronized groups; Xcode 15 cannot open this project format even though the app targets **iOS 16+**.
2. Allow Swift Package Manager to resolve GoogleMaps **9.4.0** and GooglePlaces **9.4.1**. These pinned SDKs support iOS 15 and later. All dependencies use SPM; the resolution file is committed.
3. Choose an iPhone or iPad simulator and Run. No backend, account, or token is required for the demo.
4. Browse sample vendors, favorite them, and use search to add “Waterfront” or “Bakery”. Open Settings to save, explicitly reveal, and clear a token.

Without keys, the app shows a map setup panel and uses clearly labeled mock Places. **This does not constitute a completed live Google Maps demo.** Supply a working map key before recording the assignment.

## Google configuration

Copy `Config/Local.xcconfig.example` to `Config/Local.xcconfig` and replace placeholders. The local file is ignored by Git; never paste keys into tracked files.

```xcconfig
GOOGLE_MAPS_API_KEY = your_maps_key
GOOGLE_PLACES_API_KEY = your_places_key
USE_MOCK_PLACES = YES
```

In Google Cloud, enable billing and Maps SDK for iOS. For live search, enable the Places API required by the pinned iOS SDK and set `USE_MOCK_PLACES = NO`. Restrict each key to the iOS bundle identifier `com.nathan.Vendor-Locator` and its required API. Rebuild after configuration changes. For a physical device, choose your signing team in Xcode and update bundle restrictions if you change the bundle ID.

The live adapter uses `GMSPlacesClient`, autocomplete predictions and place-details requests with a shared session token; a token is rotated after a details request and a new search sheet creates a fresh session. Searches are restricted to South Africa. No location permission is requested.

SDK configuration references: [Maps setup](https://developers.google.com/maps/documentation/ios-sdk/config), [Places setup](https://developers.google.com/maps/documentation/places/ios-sdk/config), [attributions](https://developers.google.com/maps/documentation/places/ios-sdk/policies).

## REST contract and demo scenarios

`GET https://vendor-locator.example/vendors` returns a JSON array. A dedicated ephemeral URLSession intercepts this demo host locally through URLProtocol; no request or token goes to the network. A real URLSession and HTTPS endpoint can be injected into `VendorServiceImpl` without changing the UI. Requests accept JSON and add `Authorization: Bearer <stored-token>` when a token exists.

```json
[{"id":"ven-001","name":"Mr D Pizza — Cape Town CBD","address":"12 Loop St, Cape Town, 8000","coordinate":{"lat":-33.918861,"lng":18.423300},"isFavorite":false,"updatedAt":"2025-06-01T12:00:00Z"}]
```

Use Product → Scheme → Edit Scheme → Run → Arguments:

| Argument | Behavior |
| --- | --- |
| none | Four vendors after a short simulated delay |
| `--vendors-error` | Every vendor request returns HTTP 503 |
| `--vendors-empty` | Empty JSON array |
| `--vendors-fail-refresh-once` | First load succeeds, second request fails, retry succeeds |

In mock Places, search `error` to exercise search failure. Remove launch arguments to return to normal. Favorites and added places survive refresh, but reset when the app process ends. Only the session token persists.

## Tests

Run Product → Test, or substitute an available simulator name in:

```sh
xcodebuild -project 'Vendor Locator.xcodeproj' -scheme 'Vendor Locator' \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath DerivedData test
```

**Validation status:** the pre-refactor simulator build passed. After the architecture refactor, Swift syntax checks passed, but build and test execution remain unverified: Xcode cache access was blocked and expanded build access was declined. See SOLUTION.md.

Unit tests cover repository merging/favorite overrides, refresh failure and cancellation, shared observations, search races and dismissal, DTO validation, and authenticated REST requests. One UI workflow test exercises refresh failure/retry, mock search/add, and Keychain persistence across relaunch followed by cleanup. It uses a disposable demo token; run on a test simulator.

See `SOLUTION.md` for design and verification limits, and `DEMO.md` for a 7-minute recording guide.

## Architecture

- `App/`: service dependency construction, network URL constants, bundle configuration, and isolated preview dependencies.
- `Features/Vendors/Domain/`: app models and loading/repository contracts.
- `Features/Vendors/Services/`: REST DTO mapping and the session-scoped in-memory repository.
- `Features/Vendors/View/`: screen model, map adapter, and vendor UI components.
- `Features/PlaceSearch/`: search contract, Google/mock adapters, and a testable search view model.
- `Features/Settings/`: token settings using injected storage and service labels.
- `Infrastructure/`: transport errors and Keychain storage.
- `SharedUI/`: reusable retry presentation.

Favorites and added places still last for the current session. The repository makes that policy explicit; no persistent vendor storage has been added. The App composition root still selects the demo vendor transport.

## Localization (l10n)

English is the only supported language. App copy lives in `Vendor Locator/L10n/Localizable.xcstrings` and is accessed through the typed `L10n` namespace. Edit the catalog for wording changes; add a matching accessor when introducing a new key. Vendor counts use plural variations, and accessibility actions and storage errors use complete formatted phrases. Vendor names, addresses, and provider attribution remain content rather than translation keys.

## Design system

`DesignSystem/` provides the `DS` tokens, reusable SwiftUI controls, and a preview gallery for light, dark, and accessibility text sizes. Screens share these styles while retaining native lists, forms, and navigation. See [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) for usage and validation limits.

## Naming

App-owned protocols use the `Protocol` suffix: `VendorServiceProtocol`, `VendorRepositoryProtocol`, `PlacesServiceProtocol`, and `TokenStoreProtocol`. Implementations describe their technology or behavior: `VendorServiceImpl`, `VendorRepositoryImpl`, `PlacesServiceImpl`, `MockPlacesServiceImpl`, and `TokenStoreImpl`. Test doubles use `Stub`, `Controlled`, or `Suspended` prefixes. Apple's protocol names remain unchanged; `DemoVendorURLProtocol` and `StubVendorURLProtocol` are subclasses of Foundation's `URLProtocol` class.

## Network executor and view previews

`NetworkExecutorProtocol` accepts a prepared `URLRequest` and returns response `Data`. `NetworkExecutorImpl` owns HTTP validation and cancellation checks, preserving status codes while mapping raw transport errors into a closed `TransportError` enum. `VendorServiceImpl` injects this boundary and owns authentication, ISO-8601 DTO decoding, and domain mapping. `AppDependencies` creates the demo URLSession and executor; live or stub executors can be substituted without changing feature logic.

Every app View and UIViewRepresentable has a preview in its source file. ContentView covers loading, populated, empty, and error states; PlaceSearchView covers idle, results, empty, and error states. Settings uses an isolated memory token store. GoogleMapView requires a configured Maps key to render live tiles in Canvas and otherwise shows setup guidance. That preview initializes the Google SDK and can make Google requests when configured; the other previews use local data.

Executor tests cover successful/empty responses, non-HTTP responses, HTTP errors, timeouts, and cancellation. Source syntax and preview coverage can be checked locally; full build, rendered previews, and test execution remain unverified under the previously declined Xcode cache permissions.

## Encapsulated errors and previews

All throwing service, repository, and token-store protocols now use typed throws. The network executor exposes only `TransportError`, rejects unsupported/malformed request URLs before execution, and maps URLSession failures to safe cases. Cancellation remains distinct. `VendorError`, `PlaceSearchError`, and `TokenStoreError` contain feature/storage failures; raw provider errors, response bodies, URLs, and userInfo are not retained or presented. The Settings screen displays localized storage guidance without OS status details.

Previews no longer force a color scheme; use Canvas's appearance toggle. Small design components share the debug-only `.previewCanvas()` modifier for spacing, background, and theme. It uses `ViewModifier` to support the app's iOS 16 deployment target.

## Parsing, dependencies, and implementation names

App-owned protocol implementations use `Impl`: `VendorRepositoryImpl`, `VendorServiceImpl`, `NetworkExecutorImpl`, `PlacesServiceImpl`, `TokenStoreImpl`, and `DataParserImpl`. Alternate implementations keep a descriptive prefix such as `Mock`, `Preview`, or `Controlled` to distinguish their role. Framework types and URLProtocol subclasses retain their conventional names.

Views construct and own their view models. `AppDependencies` supplies repositories, stores, and a Places service factory; each search sheet still receives a fresh service for its autocomplete session.

`DataParserProtocol` is the JSON decoding boundary. `DataParserImpl` creates a fresh JSONDecoder per call, defaults to ISO-8601 dates, and supports an explicit date strategy. DEBUG diagnostics identify the model, coding path, and missing-key/type-mismatch/null/corruption category. They omit payloads, underlying error descriptions, and request metadata. Release builds omit those diagnostics. All parse failures leave the boundary as `DataParserError.invalidData`; the vendor service maps that to its feature error.

`Constants.Network.Vendors` groups the stable reserved demo base URL, vendor path, and derived endpoint. Keys and environment-sensitive configuration remain in `AppConfiguration`; localized copy remains in `L10n`. Test-only endpoints remain isolated in test fixtures.
