/// Only sanitized failures may cross the vendor feature's service/repository boundaries.
enum VendorError: Error, Equatable {
    case transport(TransportError)
    case invalidResponse
    case credentialsUnavailable
    case cancelled
}
