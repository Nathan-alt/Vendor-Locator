import Combine
import Foundation

/// Coordinates debounced searches and ignores obsolete asynchronous results.
@MainActor
final class PlaceSearchViewModel: ObservableObject {
    /// Represents the current search phase, results, or displayable failure.
    enum SearchState: Equatable {
        case idle, searching, results([PlaceSuggestion]), failed(String)
    }
    @Published private(set) var state: SearchState = .idle
    @Published private(set) var isAdding = false
    @Published private(set) var selectionError: String?
    private let service: any PlacesServiceProtocol
    private let debounce: () async throws -> Void
    private var searchRevision = 0
    private var selectionRevision = 0

    var results: [PlaceSuggestion] {
        if case .results(let values) = state { return values }
        return []
    }
    var errorMessage: String? {
        if let selectionError { return selectionError }
        if case .failed(let message) = state { return message }
        return nil
    }
    var isSearching: Bool { state == .searching }
    var isEmpty: Bool {
        if case .results(let values) = state { return values.isEmpty }
        return false
    }

    init(
        service: any PlacesServiceProtocol,
        debounce: @escaping () async throws -> Void = {
            try await Task.sleep(nanoseconds: 300_000_000)
        }
    ) {
        self.service = service
        self.debounce = debounce
    }

    func search(_ query: String) async {
        searchRevision += 1
        let revision = searchRevision
        selectionError = nil
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            state = .idle
            return
        }
        state = .searching
        do {
            try await debounce()
            try Task.checkCancellation()
            let values = try await service.suggestions(for: query)
            try Task.checkCancellation()
            guard revision == searchRevision else { return }
            state = .results(values)
        } catch {
            guard revision == searchRevision else { return }
            if Task.isCancelled || error is CancellationError
                || (error as? PlaceSearchError) == .cancelled
            {
                state = .idle
            } else {
                state = .failed(PlaceFailureMessage.message(error))
            }
        }
    }

    func select(_ id: String) async -> Vendor? {
        guard !isAdding else { return nil }
        selectionRevision += 1
        let revision = selectionRevision
        isAdding = true
        selectionError = nil
        defer { if revision == selectionRevision { isAdding = false } }
        do {
            let vendor = try await service.details(for: id)
            try Task.checkCancellation()
            guard revision == selectionRevision else { return nil }
            return vendor
        } catch {
            guard revision == selectionRevision, !Task.isCancelled,
                !(error is CancellationError), (error as? PlaceSearchError) != .cancelled
            else { return nil }
            selectionError = PlaceFailureMessage.message(error, selecting: true)
            return nil
        }
    }

    /// Invalidates callbacks even when the SDK cannot cancel its underlying request.

    func deactivate() {
        searchRevision += 1
        selectionRevision += 1
        state = .idle
        isAdding = false
        selectionError = nil
    }
}
