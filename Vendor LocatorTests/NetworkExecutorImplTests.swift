import XCTest

@testable import Vendor_Locator

final class NetworkExecutorImplTests: XCTestCase {

    func testReturnsSuccessfulBody() async throws {
        let body = try await executor().execute(request("success"))
        XCTAssertEqual(body, Data("response".utf8))
    }

    func testAcceptsEmpty204Response() async throws {
        let body = try await executor().execute(request("empty"))
        XCTAssertTrue(body.isEmpty)
    }

    func testRejectsNonHTTPResponse() async {
        do {
            _ = try await executor().execute(request("non-http"))
            XCTFail("Expected invalid response")
        } catch { XCTAssertEqual(error as? TransportError, .invalidResponse) }
    }

    func testPreservesHTTPStatus() async {
        do {
            _ = try await executor().execute(request("unauthorized"))
            XCTFail("Expected HTTP failure")
        } catch { XCTAssertEqual(error as? TransportError, .http(401)) }
    }

    func testEncapsulatesTimeout() async {
        do {
            _ = try await executor().execute(request("timeout"))
            XCTFail("Expected timeout")
        } catch { XCTAssertEqual(error as? TransportError, .timedOut) }
    }

    func testEncapsulatesURLSessionCancellation() async {
        do {
            _ = try await executor().execute(request("cancelled"))
            XCTFail("Expected cancellation")
        } catch { XCTAssertEqual(error as? TransportError, .cancelled) }
    }

    func testAlreadyCancelledTaskDoesNotReturnData() async {
        let executor = executor()
        let request = request("success")
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await executor.execute(request)
        }
        do {
            _ = try await task.value
            XCTFail("Expected task cancellation")
        } catch { XCTAssertEqual(error as? TransportError, .cancelled) }
    }

    func testRejectsUnsupportedRequestBeforeExecution() async {
        do {
            _ = try await executor().execute(URLRequest(url: URL(fileURLWithPath: "/tmp/example")))
            XCTFail("Expected invalid request")
        } catch { XCTAssertEqual(error as? TransportError, .invalidRequest) }
    }

    func testUnknownFailureDoesNotExposeUnderlyingDetails() async {
        do {
            _ = try await executor().execute(request("unknown"))
            XCTFail("Expected sanitized failure")
        } catch { XCTAssertEqual(error as? TransportError, .unavailable) }
    }

    func testClassifiesOfflineAndTLSFailures() {
        XCTAssertEqual(TransportError.encapsulating(URLError(.notConnectedToInternet)), .offline)
        XCTAssertEqual(
            TransportError.encapsulating(URLError(.serverCertificateUntrusted)),
            .secureConnectionFailed
        )
        XCTAssertEqual(
            TransportError.encapsulating(URLError(.networkConnectionLost)),
            .connectionFailed
        )
    }

    private func executor() -> NetworkExecutorImpl {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ExecutorStubURLProtocol.self]
        return NetworkExecutorImpl(session: URLSession(configuration: configuration))
    }

    private func request(_ scenario: String) -> URLRequest {
        URLRequest(url: URL(string: "https://executor-tests.example/\(scenario)")!)
    }
}

/// Every scenario belongs to its request; tests share no mutable response handlers.
private final class ExecutorStubURLProtocol: URLProtocol {

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "executor-tests.example"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        let scenario = url.lastPathComponent
        if scenario == "unknown" {
            client?
                .urlProtocol(
                    self,
                    didFailWithError: NSError(
                        domain: "PrivateProvider",
                        code: 17,
                        userInfo: [NSLocalizedDescriptionKey: "Sensitive implementation details"]
                    )
                )
            return
        }
        if scenario == "timeout" || scenario == "cancelled" {
            client?
                .urlProtocol(
                    self,
                    didFailWithError: URLError(scenario == "timeout" ? .timedOut : .cancelled)
                )
            return
        }
        let response: URLResponse
        if scenario == "non-http" {
            response = URLResponse(
                url: url,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
        } else {
            let status = scenario == "unauthorized" ? 401 : (scenario == "empty" ? 204 : 200)
            response = HTTPURLResponse(
                url: url,
                statusCode: status,
                httpVersion: nil,
                headerFields: nil
            )!
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: scenario == "empty" ? Data() : Data("response".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class ErrorEncapsulationTests: XCTestCase {

    func testPlacesDiscardsUnknownProviderDetails() {
        let error = NSError(
            domain: "PrivateProvider",
            code: 99,
            userInfo: [NSLocalizedDescriptionKey: "Internal request details"]
        )
        XCTAssertEqual(PlaceSearchError.encapsulating(error), .unavailable)
    }

    func testPlacesPreservesCancellationAndKnownFailures() {
        XCTAssertEqual(PlaceSearchError.encapsulating(CancellationError()), .cancelled)
        XCTAssertEqual(PlaceSearchError.encapsulating(URLError(.cancelled)), .cancelled)
        XCTAssertEqual(PlaceSearchError.encapsulating(PlaceSearchError.missingPlace), .missingPlace)
    }
}
