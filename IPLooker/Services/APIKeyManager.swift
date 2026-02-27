import Foundation
import Security

enum APIKeyManager {
    /// Maps service names to their Info.plist key names (sourced from Secrets.xcconfig).
    private static let infoPlistKeys: [String: String] = [
        "ipapi.is": "IPAPI_IS_KEY",
        "ipdata.co": "IPDATA_CO_KEY",
        "ipgeolocation.io": "IPGEOLOCATION_IO_KEY",
        "ipinfo.io": "IPINFO_IO_KEY",
        "iplocate.io": "IPLOCATE_IO_KEY",
    ]

    private static let keychainServicePrefix = "com.dannystewart.IPLooker.apikey."

    // MARK: - Public API

    static func key(for service: String, requiresUserKey: Bool = false) -> String {
        if let userKey = userKey(for: service), !userKey.isEmpty {
            return userKey
        }

        if requiresUserKey {
            return ""
        }

        guard
            let plistKey = infoPlistKeys[service],
            let value = Bundle.main.object(forInfoDictionaryKey: plistKey) as? String,
            !value.isEmpty else
        {
            return ""
        }

        return value
    }

    // MARK: - User Key Management (Keychain)

    static func userKey(for service: String) -> String? {
        let account = self.keychainServicePrefix + service
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func setUserKey(_ key: String, for service: String) {
        let account = self.keychainServicePrefix + service

        self.deleteUserKey(for: service)

        guard !key.isEmpty, let data = key.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func deleteUserKey(for service: String) {
        let account = self.keychainServicePrefix + service
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
