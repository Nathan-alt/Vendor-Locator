import Foundation

/// Closed transport failures. Never retain raw errors, URLs, response bodies, or userInfo.
enum TransportError: Error, Equatable {
    case http(Int)
    case invalidRequest
    case invalidResponse
    case cancelled
    case timedOut
    case offline
    case connectionFailed
    case secureConnectionFailed
    case unavailable

    static func encapsulating(_ error: Error) -> TransportError {
        if Task.isCancelled || error is CancellationError { return .cancelled }
        if let known = error as? TransportError { return known }
        guard let error = error as? URLError else { return .unavailable }
        switch error.code {
        case .cancelled: return .cancelled
        case .timedOut: return .timedOut
        case .notConnectedToInternet: return .offline
        case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .networkConnectionLost:
            return .connectionFailed
        case .secureConnectionFailed, .serverCertificateHasBadDate, .serverCertificateUntrusted,
            .serverCertificateHasUnknownRoot, .serverCertificateNotYetValid,
            .clientCertificateRejected, .clientCertificateRequired:
            return .secureConnectionFailed
        case .badURL, .unsupportedURL: return .invalidRequest
        case .badServerResponse: return .invalidResponse
        default: return .unavailable
        }
    }
}
