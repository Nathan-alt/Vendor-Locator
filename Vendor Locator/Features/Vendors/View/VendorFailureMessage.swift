import Foundation

/// Maps typed vendor failures to localized screen messages.
enum VendorFailureMessage {

    static func message(_ error: VendorError) -> String {
        if case VendorError.invalidResponse = error {
            return L10n.vendorResponseInvalid
        }
        return L10n.vendorLoadFailed
    }

}
