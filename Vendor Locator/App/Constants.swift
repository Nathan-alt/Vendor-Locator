import Foundation

/// Stable network routes only. Environment configuration stays in AppConfiguration;
/// user-facing copy stays in L10n. This reserved demo host is intercepted locally.
enum Constants {
    /// Groups stable network endpoint constants.
    enum Network {
        /// Defines the locally intercepted vendor demo endpoint and path.
        enum Vendors {
            static let demoBaseURL = URL(string: "https://vendor-locator.example")!
            static let listPath = "vendors"
            static let demoEndpoint = demoBaseURL.appendingPathComponent(listPath)
        }
    }
}
