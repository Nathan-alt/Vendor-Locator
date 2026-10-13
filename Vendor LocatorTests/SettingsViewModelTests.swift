import XCTest

@testable import Vendor_Locator

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private let services = ServicePresentation(
        isMockPlaces: true,
        isMapConfigured: false,
        vendorSourceName: "Test"
    )

    func testSavingTrimsInputAndClearsSensitiveState() {
        let store = StubTokenStoreImpl()
        let model = SettingsViewModel(tokenStore: store, services: services)
        model.input = "  token-value  "

        model.saveToken()

        XCTAssertEqual(store.savedToken, "token-value")
        XCTAssertTrue(model.input.isEmpty)
        XCTAssertEqual(model.message, L10n.tokenSaved)
        XCTAssertFalse(model.messageIsError)
    }

    func testRevealingAndHidingToken() {
        let store = StubTokenStoreImpl()
        store.storedToken = "token-value"
        let model = SettingsViewModel(tokenStore: store, services: services)

        model.revealToken()

        XCTAssertEqual(model.revealedToken, "token-value")
        XCTAssertEqual(model.message, L10n.tokenRevealed)

        model.hideToken()

        XCTAssertNil(model.revealedToken)
    }

    func testStorageFailureShowsSanitizedMessage() {
        let store = StubTokenStoreImpl()
        store.error = .unavailable
        let model = SettingsViewModel(tokenStore: store, services: services)
        model.input = "token-value"

        model.saveToken()

        XCTAssertEqual(model.message, L10n.secureStorageFailure)
        XCTAssertTrue(model.messageIsError)
        XCTAssertNil(model.revealedToken)
    }

    func testClearingSensitiveStatePreservesStatusMessage() {
        let store = StubTokenStoreImpl()
        store.storedToken = "token-value"
        let model = SettingsViewModel(tokenStore: store, services: services)
        model.input = "draft"
        model.revealToken()

        model.clearSensitiveState()

        XCTAssertTrue(model.input.isEmpty)
        XCTAssertNil(model.revealedToken)
        XCTAssertEqual(model.message, L10n.tokenRevealed)
    }
}

private final class StubTokenStoreImpl: TokenStoreProtocol {
    var storedToken: String?
    var savedToken: String?
    var error: TokenStoreError?

    func read() throws(TokenStoreError) -> String? {
        if let error {
            throw error
        }
        return storedToken
    }

    func save(_ token: String) throws(TokenStoreError) {
        if let error {
            throw error
        }
        savedToken = token
        storedToken = token
    }

    func clear() throws(TokenStoreError) {
        if let error {
            throw error
        }
        storedToken = nil
    }
}
