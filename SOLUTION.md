# Design and trade-offs

## Structure

The app retains MVVM, with feature folders for Vendors, PlaceSearch, and Settings. The Xcode synchronized source group picks up these folders without manual file references. These are responsibility boundaries inside one target, not independently enforced Swift modules.

`AppDependencies` is the composition root: it creates the session-scoped repository, Keychain store, service presentation settings, and a Places service factory for each search screen. Runtime bundle configuration is read in the App folder. Screens receive their dependencies explicitly, including Settings; they do not choose live versus mock services. Each search presentation gets a fresh Places adapter and autocomplete session. Views construct their own view models; dependencies never construct view models. `PreviewDependencies` supplies independent in-memory stores and populated, empty, failed, and loading scenarios without Keychain or Google requests.

`VendorServiceProtocol` defines the remote-source boundary. `VendorServiceImpl` builds the authenticated request at call time, delegates HTTP execution/validation to an injected `NetworkExecutorProtocol`, uses `DataParserProtocol` to decode a separate `VendorDTO`, and maps it into `Vendor`. Mapping rejects empty IDs and invalid coordinates. Domain models do not conform to Codable or import Google SDKs. `TransportError` carries HTTP/response facts; presentation features map failures to contextual messages. The Keychain wrapper exposes a closed `TokenStoreError`.

`VendorRepositoryImpl` owns the collection, additions, deduplication, and favorite overrides on the main actor. Remote records win duplicate IDs; explicit local favorite choices win over either source. Failed/cancelled reloads retain existing data. Reload requests are serialized; an overlapping reload is ignored. Its Combine publisher provides the current snapshot and subsequent updates to observing view models. Storage remains session-only.

`VendorViewModel` owns screen selection and an explicit load state, observes repository changes, and forwards add/favorite actions. Refresh leaves loaded content visible. Cancellation restores the previous load state without showing an error. Selection clears when its vendor disappears, and repeated row selection still increments the camera revision.

`PlaceSearchViewModel` owns debouncing, search results/errors, detail selection, and request generations. The view supplies task lifecycle and dismissal. Revision checks and cancellation checks prevent obsolete results from replacing newer searches or completing after dismissal, even when the underlying SDK request cannot be cancelled. The debounce closure is injectable for deterministic tests.

Reusable UI is limited to focused components: `VendorRow`, `VendorMapSection`, `EmptyVendorsView`, `PlaceSuggestionRow`, and `LoadFailureView`. The existing Google Maps adapter keeps marker/camera behavior isolated from screen orchestration.

## Google Maps and Places

GoogleMaps 9.4.0 and GooglePlaces 9.4.1 are installed through SPM and pinned with Package.resolved. Their minimum OS is compatible with iOS 16. This conservative pin keeps the exercise reproducible; a production app should periodically review SDK support and upgrades. The existing Xcode 26.2 project format is retained, with non-iOS platforms removed and all targets lowered to iOS 16.

`GoogleMapView` bridges GMSMapView into SwiftUI. Its coordinator retains markers by vendor ID, removes obsolete markers, and updates marker content. The camera fits the first set of vendors once; an explicit selection revision causes recentering even when a row is tapped again. Favorite changes do not move the camera. Semantic SwiftUI colors follow system appearance; a local JSON map style updates in dark mode without recreating the map. Google map attribution remains unobscured.

Exactly one Places enhancement is implemented: search and add. Search is debounced by 300 ms, and cancelled/stale task results cannot replace current results. Selecting a suggestion fetches only the required place fields. Place IDs prevent duplicates. SDK callbacks are bridged with checked continuations; task cancellation suppresses obsolete UI updates, but does not cancel an already submitted Google request. Live search displays Google Maps attribution and preserves any returned third-party attribution text/links with the vendor. A search sheet owns an autocomplete session, completing it on details fetch. Country filtering keeps this exercise focused on South Africa.

Mock Places is deterministic and explicitly labeled, using fictional vendors. The live SDK adapter is compiled into the app and selected through configuration. No keys were supplied during implementation: the keyless map setup screen is intentionally not a substitute map implementation. Live tiles, key restrictions, Places billing/API enablement, and real search responses require verification with working credentials.

## Secure storage

The Keychain wrapper scopes a generic-password item by service/account. Updates use SecItemUpdate, adding only when no item exists. Reads/deletes treat item-not-found as normal. Other OSStatus values map to a typed storage failure with localized guidance; raw OS status details are not presented. Accessibility is WhenUnlockedThisDeviceOnly: the item does not migrate to another device and requires an unlocked device.

Settings uses secure entry and explicit reveal. It clears sensitive view state when inactive. Tokens are neither logged nor saved in UserDefaults. They are read for every vendor request so save/clear takes effect immediately. The demo token never leaves the local URLProtocol. Client Google API keys are separate from the session token; ignored xcconfig files prevent accidental commits but do not make keys embedded in an app secret, so bundle/API restrictions are required.

## Scope and limitations

Sample vendors start in Cape Town. No user location, distance ranking, persistent favorites, offline cache, clustering, second Places enhancement, CI, or Fastlane is included. Google Places results remain in memory for the session. Network errors use friendly descriptions; production authentication/401 flows are outside this exercise. The demo data is illustrative, not a verified business directory.

The app targets iPhone and iPad with native lists/forms, scalable text, and named accessibility actions. Before publishing a real product, supply product-specific terms/privacy disclosures for Google services and review current platform terms. This repository is a take-home demo, not a public release.

## Verification

- Google package resolution succeeded and exact versions/revisions are recorded.
- The final iOS Simulator app build passed on Xcode 26.2, including both live Google adapters.
- Inspected the built Info.plist: minimum OS is 16.0, Google configuration keys are present, and mock Places defaults to YES.
- Unit and UI test targets compiled during an earlier test build. Runtime execution did not complete: the Mac initially ran out of disk space; after space was freed, the iOS 26.2 simulator booted but installation/test startup remained stalled. No test pass is claimed.
- A separate temporary macOS test harness was attempted, but compiler-cache access required permission that was not granted; it did not run. A final build-for-testing request was also declined.
- Manual UI, VoiceOver, Dynamic Type, appearance switching, and Keychain runtime checks remain unverified. Use README scenarios and DEMO.md after restarting the simulator in a healthy environment.
- Live map tiles, camera behavior, and Google Places responses remain unverified without credentials. No iOS 16 runtime is installed locally; the deployment target provides compile-time compatibility checks only.

## Architecture refactor verification (12 October 2026)

Swift frontend parsing passed for the app and unit-test sources after the refactor. This validates syntax only, not type checking, linking, macro expansion, or runtime behavior. Xcode build failed before source compilation because its external compiler/package caches were sandbox-blocked; the expanded-access build-for-testing request was declined. The refactor's build and tests therefore remain unverified.

Added tests cover repository merge precedence, favorite preservation, failure/retry, cancellation, overlapping reload suppression, multi-screen observations, selection removal, search races, cancelled debounce, dismissal, detail failure/retry, DTO mapping, HTTP/decoding failures, and per-request token/headers. Existing UI workflow assertions and accessibility labels are retained. Run Product → Test in Xcode to complete validation.
