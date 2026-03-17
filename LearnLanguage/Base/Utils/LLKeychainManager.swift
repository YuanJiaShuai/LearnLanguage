//
//  LLKeychainManager.swift
//  LearnLanguage
//
//  Keychain 管理器 - 安全存储数据库密码

import Foundation
import Security

final class LLKeychainManager {
    
    static let shared = LLKeychainManager()
    
    private let service = "com.learnlanguage.db"
    private let account = "database_cipher_key"
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 获取或创建数据库密码
    func getDatabasePassword() -> String {
        // 先尝试从 Keychain 获取
        if let existingPassword = retrievePassword() {
            LLLogger.info("🔐 从 Keychain 获取数据库密码成功")
            LLLogger.info("🔑 数据库密码：\(existingPassword)")
            return existingPassword
        }
        
        // 如果不存在，生成新密码并保存
        let newPassword = generateRandomPassword()
        savePassword(newPassword)
        LLLogger.info("🔐 生成并保存新的数据库密码")
        LLLogger.info("🔑 数据库密码：\(newPassword)")
        return newPassword
    }
    
    /// 清除密码（用于测试）
    func clearPassword() {
        deletePassword()
        LLLogger.warn("🔐 已清除 Keychain 中的数据库密码")
    }
    
    // MARK: - Private Methods
    
    /// 从 Keychain 获取密码
    private func retrievePassword() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    /// 保存密码到 Keychain
    private func savePassword(_ password: String) {
        guard let data = password.data(using: .utf8) else {
            LLLogger.error("❌ 密码编码失败")
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // 先删除旧的
        SecItemDelete(query as CFDictionary)
        
        // 再添加新的
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            LLLogger.debug("✅ 密码已保存到 Keychain")
        } else {
            LLLogger.error("❌ 保存密码到 Keychain 失败：\(status)")
        }
    }
    
    /// 从 Keychain 删除密码
    private func deletePassword() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    /// 生成随机密码（32 字节 = 256 位）
    private func generateRandomPassword() -> String {
        var randomBytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        
        guard status == errSecSuccess else {
            LLLogger.error("❌ 生成随机密码失败")
            // 降级方案：使用 UUID
            return UUID().uuidString
        }
        
        // 转换为十六进制字符串
        let hexString = randomBytes.map { String(format: "%02x", $0) }.joined()
        return hexString
    }
}
