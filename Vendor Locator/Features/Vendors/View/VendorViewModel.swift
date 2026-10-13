import Combine
import Foundation

/// Owns vendor screen state and forwards collection changes to the repository.
@MainActor
final class VendorViewModel: ObservableObject {
    /// Tracks the vendor screen loading lifecycle and its displayable failure message.
    enum LoadState: Equatable {
        case idle, loading, loaded, failed(String)
    }
    @Published private(set) var vendors: [Vendor] = []
    @Published private(set) var state: LoadState = .idle
    @Published private(set) var selectedID: String?
    @Published private(set) var selectionRevision = 0
    private let repository: any VendorRepositoryProtocol
    private var subscription: AnyCancellable?

    var isLoading: Bool { state == .loading }
    var errorMessage: String? {
        if case .failed(let message) = state { return message }
        return nil
    }

    init(repository: any VendorRepositoryProtocol) {
        self.repository = repository
        subscription = repository.updates.sink { [weak self] vendors in
            guard let self else { return }
            self.vendors = vendors
            if let id = self.selectedID, !vendors.contains(where: { $0.id == id }) {
                self.selectedID = nil
            }
        }
    }

    func reload() async {
        guard !isLoading else { return }
        let previous = state
        state = .loading
        do {
            try await repository.reload()
            guard !Task.isCancelled else {
                state = previous
                return
            }
            state = .loaded
        } catch {
            state = error == .cancelled ? previous : .failed(VendorFailureMessage.message(error))
        }
    }

    func toggleFavorite(_ id: String) { repository.toggleFavorite(id) }

    func select(_ id: String) {
        guard vendors.contains(where: { $0.id == id }) else { return }
        selectedID = id
        selectionRevision += 1
    }

    func add(_ vendor: Vendor) {
        repository.add(vendor)
        select(vendor.id)
    }
}
