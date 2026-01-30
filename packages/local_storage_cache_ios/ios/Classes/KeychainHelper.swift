import Foundation
import Security

/**
 * KeychainHelper
 * 
 * Provides secure storage using iOS Keychain Services.
 */
class KeychainHelper {
    
    private let service = "com.protheeuz.local_storage_cache"
    
    /**
     * Saves a key-value pair to the keychain.
     */
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        // Delete existing item if any
        try? delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    /**
     * Retrieves a value from the keychain.
     */
    func get(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.retrievalFailed(status)
        }
        
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodingFailed
        }
        
        return value
    }
    
    /**
     * Deletes a key from the keychain.
     */
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deletionFailed(status)
        }
    }
}

/**
 * Keychain errors
 */
enum KeychainError: Error {
    case encodingFailed
    case decodingFailed
    case saveFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case deletionFailed(OSStatus)
}
