import Foundation

/// Intercepts only the demo endpoint; no token or vendor request leaves the device.
final class DemoVendorURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var requestCount = 0
    private var work: DispatchWorkItem?
    private let deliveryLock = NSRecursiveLock()
    private var stopped = false
    private let deliveryQueue = DispatchQueue(label: "vendor.mock.delivery")

    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == Constants.Network.Vendors.demoBaseURL.host
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let item = DispatchWorkItem { [weak self] in self?.deliver() }
        work = item
        deliveryQueue.asyncAfter(deadline: .now() + 0.5, execute: item)
    }

    private func deliver() {
        deliveryLock.lock()
        defer { deliveryLock.unlock() }
        guard !stopped else { return }
        do {
            let args = ProcessInfo.processInfo.arguments
            Self.lock.lock()
            Self.requestCount += 1
            let count = Self.requestCount
            Self.lock.unlock()
            let fails =
                args.contains("--vendors-error")
                || (args.contains("--vendors-fail-refresh-once") && count == 2)
            let status = fails ? 503 : 200
            let data: Data
            if args.contains("--vendors-empty") {
                data = Data("[]".utf8)
            } else {
                guard let url = Bundle.main.url(forResource: "vendors", withExtension: "json")
                else {
                    throw TransportError.invalidResponse
                }
                data = try Data(contentsOf: url)
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }

    override func stopLoading() {
        deliveryLock.lock()
        defer { deliveryLock.unlock() }
        stopped = true
        work?.cancel()
    }
}
