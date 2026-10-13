import Foundation

/// Executes HTTP requests and maps URLSession failures to safe transport errors.
struct NetworkExecutorImpl: NetworkExecutorProtocol {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    func execute(_ request: URLRequest) async throws(TransportError) -> Data {
        guard !Task.isCancelled else { throw .cancelled }
        guard let url = request.url,
            let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme),
            let host = url.host, !host.isEmpty
        else { throw .invalidRequest }
        do {
            let (data, response) = try await session.data(for: request)
            guard !Task.isCancelled else { throw TransportError.cancelled }
            guard let http = response as? HTTPURLResponse else {
                throw TransportError.invalidResponse
            }
            guard (200..<300).contains(http.statusCode) else {
                throw TransportError.http(http.statusCode)
            }
            return data
        } catch {
            throw TransportError.encapsulating(error)
        }
    }
}
