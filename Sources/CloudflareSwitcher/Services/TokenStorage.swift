import Foundation
import Security

/// Layanan penyimpanan aman untuk Cloudflare Tunnel Token menggunakan macOS Keychain
public final class TokenStorage {
    public static let shared = TokenStorage()

    private let serviceName = "com.antigravity.CloudflareSwitcher"
    private let accountName = "CloudflareTunnelToken"
    private let fallbackKey = "CF_TUNNEL_TOKEN_FALLBACK"

    private init() {}

    /// Menyimpan token tunnel
    @discardableResult
    public func saveToken(_ token: String) -> Bool {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = trimmed.data(using: .utf8) else { return false }

        // Coba simpan ke Keychain terlebih dahulu
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]

        SecItemDelete(query as CFDictionary)

        var newAttributes = query
        newAttributes[kSecValueData as String] = data
        newAttributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock

        let status = SecItemAdd(newAttributes as CFDictionary, nil)
        if status == errSecSuccess {
            // Bersihkan fallback jika ada
            UserDefaults.standard.removeObject(forKey: fallbackKey)
            return true
        } else {
            // Fallback ke UserDefaults (base64 encoded) jika Keychain dibatasi di mode dev / ad-hoc CLI
            let base64 = data.base64EncodedString()
            UserDefaults.standard.set(base64, forKey: fallbackKey)
            return true
        }
    }

    /// Mengambil token tunnel yang tersimpan
    public func getToken() -> String? {
        // Coba baca dari Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecSuccess, let data = item as? Data, let token = String(data: data, encoding: .utf8) {
            return token.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Cek fallback
        if let base64 = UserDefaults.standard.string(forKey: fallbackKey),
           let data = Data(base64Encoded: base64),
           let token = String(data: data, encoding: .utf8) {
            return token.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    /// Menghapus token tunnel
    @discardableResult
    public func deleteToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountName
        ]
        SecItemDelete(query as CFDictionary)
        UserDefaults.standard.removeObject(forKey: fallbackKey)
        return true
    }

    /// Cek apakah token sudah tersimpan
    public var hasToken: Bool {
        guard let token = getToken() else { return false }
        return !token.isEmpty
    }
}
