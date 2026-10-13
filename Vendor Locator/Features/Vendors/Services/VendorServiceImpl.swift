import Foundation

/// Builds authenticated vendor requests and maps parsed DTOs into domain models.
struct VendorServiceImpl: VendorServiceProtocol {
    let executor: any NetworkExecutorProtocol
    let tokens: any TokenStoreProtocol
    let endpoint: URL
    let parser: any DataParserProtocol

    init(
        executor: any NetworkExecutorProtocol,
        tokens: any TokenStoreProtocol,
        endpoint: URL,
        parser: any DataParserProtocol = DataParserImpl()
    ) {
        self.executor = executor
        self.tokens = tokens
        self.endpoint = endpoint
        self.parser = parser
    }

    func load() async throws(VendorError) -> [Vendor] {
        var request = URLRequest(url: endpoint)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        guard !Task.isCancelled else { throw .cancelled }
        do {
            if let token = try tokens.read(), !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        } catch { throw .credentialsUnavailable }
        let data: Data
        do { data = try await executor.execute(request) } catch {
            if error == .cancelled { throw .cancelled }
            throw .transport(error)
        }
        guard !Task.isCancelled else { throw .cancelled }
        do { return try parser.parse(data, as: [VendorDTO].self).map { try $0.vendor() } } catch {
            throw VendorError.invalidResponse
        }
    }

}
