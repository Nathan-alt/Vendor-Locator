import Foundation

/// Defines typed read, save, and clear operations for session tokens.
protocol TokenStoreProtocol {

    func read() throws(TokenStoreError) -> String?

    func save(_ token: String) throws(TokenStoreError)

    func clear() throws(TokenStoreError)
}
