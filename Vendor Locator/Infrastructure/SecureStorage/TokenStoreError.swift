import Foundation

/// Represents sanitized storage failures with localized user guidance.
enum TokenStoreError: LocalizedError, Equatable {
    case unavailable
    case invalidData

    var errorDescription: String? { L10n.secureStorageFailure }
}
