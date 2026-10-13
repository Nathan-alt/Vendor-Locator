import Foundation
import Security

/// Stores the session token in device-only Keychain storage.
struct TokenStoreImpl: TokenStoreProtocol {
    private var query: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.nathan.Vendor-Locator.session",
            kSecAttrAccount as String: "api-token",
        ]
    }

    func read() throws(TokenStoreError) -> String? {
        var request = query
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        try check(status)
        guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            throw TokenStoreError.invalidData
        }
        return token
    }

    func save(_ token: String) throws(TokenStoreError) {
        let attributes: [String: Any] = [
            kSecValueData as String: Data(token.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            try check(SecItemAdd(query.merging(attributes) { _, new in new } as CFDictionary, nil))
        } else {
            try check(status)
        }
    }

    func clear() throws(TokenStoreError) {
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecItemNotFound { try check(status) }
    }

    private func check(_ status: OSStatus) throws(TokenStoreError) {
        guard status == errSecSuccess else { throw TokenStoreError.unavailable }
    }
}
