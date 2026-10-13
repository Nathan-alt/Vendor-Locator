import Combine
import Foundation

/// Owns settings presentation state and coordinates secure token storage.
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var input = ""
    @Published private(set) var revealedToken: String?
    @Published private(set) var message: String?
    @Published private(set) var messageIsError = false

    let services: ServicePresentation

    private let tokenStore: any TokenStoreProtocol

    var isSaveDisabled: Bool {
        trimmedInput.isEmpty
    }

    init(tokenStore: any TokenStoreProtocol, services: ServicePresentation) {
        self.tokenStore = tokenStore
        self.services = services
    }

    func saveToken() {
        do {
            try tokenStore.save(trimmedInput)
            input = ""
            revealedToken = nil
            showSuccess(L10n.tokenSaved)
        } catch {
            show(error)
        }
    }

    func revealToken() {
        do {
            revealedToken = try tokenStore.read()
            showSuccess(revealedToken == nil ? L10n.noToken : L10n.tokenRevealed)
        } catch {
            show(error)
        }
    }

    func hideToken() {
        revealedToken = nil
    }

    func clearToken() {
        do {
            try tokenStore.clear()
            input = ""
            revealedToken = nil
            showSuccess(L10n.tokenCleared)
        } catch {
            show(error)
        }
    }

    func clearSensitiveState() {
        input = ""
        revealedToken = nil
    }

    private var trimmedInput: String {
        input.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func showSuccess(_ message: String) {
        self.message = message
        messageIsError = false
    }

    private func show(_ error: TokenStoreError) {
        revealedToken = nil
        message = error.localizedDescription
        messageIsError = true
    }
}
