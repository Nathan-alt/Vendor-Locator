import XCTest

@testable import Vendor_Locator

final class VendorServiceImplTests: XCTestCase {

    func testReadsCurrentTokenForEachRequestAndMapsDTO() async throws {
        let tokens = InMemoryTokenStoreImpl()
        let service = makeService(tokens: tokens)
        tokens.token = "first-token"
        let vendors = try await service.load()
        XCTAssertEqual(vendors.first?.id, "remote")
        XCTAssertEqual(vendors.first?.name, "Bearer first-token")
        tokens.token = "second-token"
        let updated = try await service.load()
        XCTAssertEqual(updated.first?.name, "Bearer second-token")
        tokens.token = nil
        let cleared = try await service.load()
        XCTAssertEqual(cleared.first?.name, "No authorization")
        XCTAssertEqual(tokens.reads, 3)
    }

    func testSendsAuthorizationAndAcceptHeaders() async throws {
        let tokens = InMemoryTokenStoreImpl()
        tokens.token = "expected-token"
        _ = try await makeService(tokens: tokens, scenario: "headers").load()
    }

    func testHTTPFailureKeepsStatus() async {
        do {
            _ = try await makeService(tokens: InMemoryTokenStoreImpl(), scenario: "server").load()
            XCTFail("Expected HTTP failure")
        } catch { XCTAssertEqual(error as? VendorError, .transport(.http(503))) }
    }

    func testMalformedPayloadIsInvalidResponse() async {
        do {
            _ = try await makeService(tokens: InMemoryTokenStoreImpl(), scenario: "invalid").load()
            XCTFail("Expected mapping failure")
        } catch { XCTAssertEqual(error as? VendorError, .invalidResponse) }
    }

    func testAcceptsInjectedExecutorWithoutURLSession() async {
        let service = VendorServiceImpl(
            executor: InvalidPayloadNetworkExecutorImpl(),
            tokens: InMemoryTokenStoreImpl(),
            endpoint: URL(string: "https://vendor-tests.example/injected")!
        )
        do {
            _ = try await service.load()
            XCTFail("Expected DTO decoding failure")
        } catch { XCTAssertEqual(error as? VendorError, .invalidResponse) }
    }

    private func makeService(tokens: InMemoryTokenStoreImpl, scenario: String = "success")
        -> VendorServiceImpl
    {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubVendorURLProtocol.self]
        return VendorServiceImpl(
            executor: NetworkExecutorImpl(session: URLSession(configuration: configuration)),
            tokens: tokens,
            endpoint: URL(string: "https://vendor-tests.example/\(scenario)")!
        )
    }
}

private final class InMemoryTokenStoreImpl: TokenStoreProtocol {
    var token: String?
    var reads = 0

    func read() throws(TokenStoreError) -> String? {
        reads += 1
        return token
    }

    func save(_ token: String) throws(TokenStoreError) { self.token = token }

    func clear() throws(TokenStoreError) { token = nil }
}

/// Request-local scenarios avoid shared mutable URLProtocol stubs across tests.
private final class StubVendorURLProtocol: URLProtocol {

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "vendor-tests.example"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let scenario = request.url!.lastPathComponent
        if scenario == "headers" {
            guard request.value(forHTTPHeaderField: "Authorization") == "Bearer expected-token",
                request.value(forHTTPHeaderField: "Accept") == "application/json"
            else {
                client?.urlProtocol(self, didFailWithError: TransportError.invalidResponse)
                return
            }
        }
        let status = scenario == "server" ? 503 : 200
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: nil,
            headerFields: nil
        )!
        let records: [[String: Any]] = [
            [
                "id": "remote",
                "name": request.value(forHTTPHeaderField: "Authorization") ?? "No authorization",
                "address": "Cape Town", "coordinate": ["lat": -33.9, "lng": 18.4],
                "isFavorite": false, "updatedAt": "2025-06-01T12:00:00Z",
            ]
        ]
        let data =
            scenario == "invalid"
            ? Data("{}".utf8) : try! JSONSerialization.data(withJSONObject: records)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private struct InvalidPayloadNetworkExecutorImpl: NetworkExecutorProtocol {

    func execute(_ request: URLRequest) async throws(TransportError) -> Data { Data("{}".utf8) }
}
