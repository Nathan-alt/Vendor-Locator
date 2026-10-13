import XCTest

@testable import Vendor_Locator

private func vendor(_ id: String = "one", name: String = "Vendor") -> Vendor {
    Vendor(
        id: id,
        name: name,
        address: "Cape Town",
        coordinate: Coordinate(lat: -33.9, lng: 18.4),
        isFavorite: false,
        updatedAt: Date(timeIntervalSince1970: 0)
    )
}

@MainActor
final class VendorRepositoryTests: XCTestCase {

    func testRemoteRecordWinsWhileLocalFavoriteWins() async throws {
        let source = ControlledVendorServiceImpl()
        let repository = VendorRepositoryImpl(source: source)
        repository.add(vendor(name: "Local"))
        repository.toggleFavorite("one")
        source.result = .success([vendor(name: "Remote"), vendor(name: "Duplicate")])
        try await repository.reload()
        XCTAssertEqual(repository.vendors.count, 1)
        XCTAssertEqual(repository.vendors.first?.name, "Remote")
        XCTAssertEqual(repository.vendors.first?.isFavorite, true)
    }

    func testFailedRefreshRetainsDataAndCanRetry() async {
        let source = ControlledVendorServiceImpl()
        source.result = .success([vendor()])
        let repository = VendorRepositoryImpl(source: source)
        let model = VendorViewModel(repository: repository)
        await model.reload()
        model.toggleFavorite("one")
        source.result = .failure(VendorError.transport(.http(503)))
        await model.reload()
        XCTAssertEqual(model.vendors.count, 1)
        XCTAssertTrue(model.vendors[0].isFavorite)
        XCTAssertNotNil(model.errorMessage)
        source.result = .success([vendor()])
        await model.reload()
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.state, .loaded)
        XCTAssertTrue(model.vendors[0].isFavorite)
    }

    func testRepositoryUpdatesReachMultipleScreens() {
        let repository = VendorRepositoryImpl(source: ControlledVendorServiceImpl())
        let first = VendorViewModel(repository: repository)
        let second = VendorViewModel(repository: repository)
        first.add(vendor())
        second.toggleFavorite("one")
        XCTAssertEqual(first.vendors, second.vendors)
        XCTAssertTrue(first.vendors[0].isFavorite)
    }

    func testCancellationDiscardsResponseAndSuppressesConcurrentReload() async {
        let source = SuspendedVendorServiceImpl()
        let model = VendorViewModel(repository: VendorRepositoryImpl(source: source))
        let started = expectation(description: "Source started")
        source.onStart = { started.fulfill() }
        let task = Task { await model.reload() }
        await fulfillment(of: [started], timeout: 1)
        await model.reload()
        XCTAssertEqual(source.calls, 1)
        task.cancel()
        source.complete([vendor()])
        await task.value
        XCTAssertTrue(model.vendors.isEmpty)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
    }

    func testSelectionClearsWhenRemoteVendorDisappears() async {
        let source = ControlledVendorServiceImpl()
        source.result = .success([vendor()])
        let model = VendorViewModel(repository: VendorRepositoryImpl(source: source))
        await model.reload()
        model.select("one")
        let revision = model.selectionRevision
        model.select("one")
        XCTAssertGreaterThan(model.selectionRevision, revision)
        source.result = .success([])
        await model.reload()
        XCTAssertNil(model.selectedID)
    }
}

@MainActor
private final class ControlledVendorServiceImpl: VendorServiceProtocol {
    var result: Result<[Vendor], VendorError> = .success([])

    func load() async throws(VendorError) -> [Vendor] { try result.get() }
}

@MainActor
private final class SuspendedVendorServiceImpl: VendorServiceProtocol {
    var calls = 0
    var onStart: (() -> Void)?
    private var continuation: CheckedContinuation<[Vendor], Never>?

    func load() async throws(VendorError) -> [Vendor] {
        calls += 1
        return await withCheckedContinuation {
            continuation = $0
            onStart?()
        }
    }

    func complete(_ vendors: [Vendor]) {
        continuation?.resume(returning: vendors)
        continuation = nil
    }
}

@MainActor
final class PlaceSearchViewModelTests: XCTestCase {

    func testOlderSearchCannotOverwriteNewerResults() async {
        let service = ControlledPlacesServiceImpl()
        let model = PlaceSearchViewModel(service: service, debounce: {})
        let oldStarted = expectation(description: "Old request started")
        service.onSearch = { if $0 == "old" { oldStarted.fulfill() } }
        let old = Task { await model.search("old") }
        await fulfillment(of: [oldStarted], timeout: 1)
        let newStarted = expectation(description: "New request started")
        service.onSearch = { if $0 == "new" { newStarted.fulfill() } }
        let new = Task { await model.search("new") }
        await fulfillment(of: [newStarted], timeout: 1)
        service.finish(
            "new",
            with: .success([PlaceSuggestion(id: "new", title: "New", subtitle: "")])
        )
        await new.value
        service.finish(
            "old",
            with: .success([PlaceSuggestion(id: "old", title: "Old", subtitle: "")])
        )
        await old.value
        XCTAssertEqual(model.results.map(\.id), ["new"])
    }

    func testDismissalSuppressesPendingSearch() async {
        let service = ControlledPlacesServiceImpl()
        let model = PlaceSearchViewModel(service: service, debounce: {})
        let started = expectation(description: "Search started")
        service.onSearch = { _ in started.fulfill() }
        let task = Task { await model.search("old") }
        await fulfillment(of: [started], timeout: 1)
        model.deactivate()
        service.finish(
            "old",
            with: .success([PlaceSuggestion(id: "old", title: "Old", subtitle: "")])
        )
        await task.value
        XCTAssertEqual(model.state, .idle)
        XCTAssertTrue(model.results.isEmpty)
    }

    func testCancelledDebounceDoesNotStartRequest() async {
        let service = ControlledPlacesServiceImpl()
        let model = PlaceSearchViewModel(service: service, debounce: { throw CancellationError() })
        await model.search("Waterfront")
        XCTAssertEqual(service.searchCount, 0)
        XCTAssertEqual(model.state, .idle)
    }

    func testBlankQuerySkipsService() async {
        let service = ControlledPlacesServiceImpl()
        let model = PlaceSearchViewModel(service: service, debounce: {})
        await model.search("   ")
        XCTAssertEqual(model.state, .idle)
        XCTAssertEqual(service.searchCount, 0)
    }

    func testSearchFailureUsesPlacesMessageAndCanRecover() async {
        let service = MockPlacesServiceImpl()
        let model = PlaceSearchViewModel(service: service, debounce: {})
        await model.search("error")
        XCTAssertEqual(model.errorMessage, "Places couldn’t be searched. Please try again.")
        await model.search("Waterfront")
        XCTAssertNil(model.errorMessage)
        XCTAssertEqual(model.results.count, 1)
    }

    func testDismissalSuppressesPendingDetails() async {
        let service = ControlledPlacesServiceImpl()
        let model = PlaceSearchViewModel(service: service, debounce: {})
        let started = expectation(description: "Details started")
        service.onDetails = { started.fulfill() }
        let selection = Task { await model.select("one") }
        await fulfillment(of: [started], timeout: 1)
        model.deactivate()
        service.finishDetails(.success(vendor()))
        let result = await selection.value
        XCTAssertNil(result)
        XCTAssertFalse(model.isAdding)
        XCTAssertNil(model.errorMessage)
    }

    func testCancelledSearchDoesNotShowError() async {
        let service = ControlledPlacesServiceImpl()
        let model = PlaceSearchViewModel(service: service, debounce: {})
        let started = expectation(description: "Search started")
        service.onSearch = { _ in started.fulfill() }
        let task = Task { await model.search("old") }
        await fulfillment(of: [started], timeout: 1)
        task.cancel()
        service.finish("old", with: .failure(PlaceSearchError.cancelled))
        await task.value
        XCTAssertEqual(model.state, .idle)
        XCTAssertNil(model.errorMessage)
    }

    func testDetailFailureLeavesResultsAvailableForRetry() async {
        let model = PlaceSearchViewModel(service: MockPlacesServiceImpl(), debounce: {})
        await model.search("Waterfront")
        let missing = await model.select("missing")
        XCTAssertNil(missing)
        XCTAssertNotNil(model.selectionError)
        XCTAssertEqual(model.results.count, 1)
        let added = await model.select(model.results[0].id)
        XCTAssertNotNil(added)
        XCTAssertNil(model.selectionError)
    }
}

@MainActor
private final class ControlledPlacesServiceImpl: PlacesServiceProtocol {
    var searchCount = 0
    var onSearch: ((String) -> Void)?
    var onDetails: (() -> Void)?
    private var searches:
        [String: CheckedContinuation<Result<[PlaceSuggestion], PlaceSearchError>, Never>] = [:]
    private var detail: CheckedContinuation<Result<Vendor, PlaceSearchError>, Never>?

    func suggestions(for query: String) async throws(PlaceSearchError) -> [PlaceSuggestion] {
        searchCount += 1
        let result: Result<[PlaceSuggestion], PlaceSearchError> = await withCheckedContinuation {
            searches[query] = $0
            onSearch?(query)
        }
        return try result.get()
    }

    func details(for id: String) async throws(PlaceSearchError) -> Vendor {
        let result: Result<Vendor, PlaceSearchError> = await withCheckedContinuation {
            detail = $0
            onDetails?()
        }
        return try result.get()
    }

    func finish(_ query: String, with result: Result<[PlaceSuggestion], PlaceSearchError>) {
        searches.removeValue(forKey: query)?.resume(returning: result)
    }

    func finishDetails(_ result: Result<Vendor, PlaceSearchError>) {
        detail?.resume(returning: result)
        detail = nil
    }
}

final class VendorDTOTests: XCTestCase {

    func testMappingPreservesAttributionAndRejectsInvalidCoordinates() throws {
        let valid = VendorDTO(
            id: "one",
            name: "Vendor",
            address: "Cape Town",
            coordinate: .init(lat: -33.9, lng: 18.4),
            isFavorite: true,
            updatedAt: Date(timeIntervalSince1970: 0),
            attributions: [.init(text: "Provider", url: URL(string: "https://example.com"))]
        )
        let mapped = try valid.vendor()
        XCTAssertTrue(mapped.isFavorite)
        XCTAssertEqual(mapped.attributions?.first?.text, "Provider")
        let invalid = VendorDTO(
            id: "one",
            name: "Vendor",
            address: "",
            coordinate: .init(lat: 91, lng: 18.4),
            isFavorite: false,
            updatedAt: Date(),
            attributions: nil
        )
        XCTAssertThrowsError(try invalid.vendor()) { error in
            XCTAssertEqual(error as? VendorError, .invalidResponse)
        }
    }
}
