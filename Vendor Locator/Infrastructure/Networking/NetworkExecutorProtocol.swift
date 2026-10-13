import Foundation

/// Executes a prepared request and returns the body of a successful HTTP response.
/// Feature services own authentication, decoding, and domain mapping.
protocol NetworkExecutorProtocol {

    func execute(_ request: URLRequest) async throws(TransportError) -> Data
}
