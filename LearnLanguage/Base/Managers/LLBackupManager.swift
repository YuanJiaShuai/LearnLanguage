//
//  LLBackupManager.swift
//  LearnLanguage
//
//  数据备份与恢复管理器
//  使用 AES-256-GCM 加密，导出格式为 .llbak，只有本软件可以解析
//

import Foundation
import CryptoKit
import MMKV

// MARK: - 错误类型

enum BackupError: Error {
    case invalidFile
    case unsupportedVersion
    case decryptionFailed
}

// MARK: - LLBackupManager

final class LLBackupManager {

    static let shared = LLBackupManager()
    private init() {}

    static let fileExtension = "llbak"

    // 文件魔数 "LLBK"
    private static let magic: [UInt8] = [0x4C, 0x4C, 0x42, 0x4B]
    private static let formatVersion: UInt8 = 1

    private var symmetricKey: SymmetricKey {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.ruijia.LearnLanguage"
        let salt = "LearnLanguage.BackupKey.v1.@ruijia#2026"
        let material = (bundleId + salt).data(using: .utf8)!
        let hash = SHA256.hash(data: material)
        return SymmetricKey(data: hash)
    }

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private let filesToBackup = [
        "LearnLanguage.db",
        "LearnLanguage.db-shm",
        "LearnLanguage.db-wal",
        "mmkv/mmkv.default",
        "mmkv/mmkv.default.crc"
    ]

    // MARK: - 导出备份

    func exportBackup(to destinationURL: URL,
                      progress: ((Double) -> Void)? = nil,
                      completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                progress?(0.05)
                let packed = try self.packFiles { p in progress?(0.05 + p * 0.55) }
                progress?(0.6)
                let encrypted = try self.encrypt(packed)
                progress?(0.8)
                let output = self.buildFileData(encrypted)
                try output.write(to: destinationURL)
                progress?(1.0)
                LLLogger.info("✅ 备份成功：\(destinationURL.lastPathComponent)，大小：\(output.count / 1024) KB")
                DispatchQueue.main.async { completion(nil) }
            } catch {
                LLLogger.error("❌ 备份失败：\(error)")
                DispatchQueue.main.async { completion("备份失败：\(error.localizedDescription)") }
            }
        }
    }

    // MARK: - 恢复备份

    func restoreBackup(from sourceURL: URL,
                       progress: ((Double) -> Void)? = nil,
                       completion: @escaping (String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            do {
                let fileData = try Data(contentsOf: sourceURL)
                progress?(0.1)
                let encrypted = try self.parseFileData(fileData)
                progress?(0.2)
                let packed = try self.decrypt(encrypted)
                progress?(0.4)
                DispatchQueue.main.sync {
                    LLDatabaseManager.shared.closeDatabase()
                    MMKV.default()?.clearAll()
                }
                progress?(0.5)
                try self.unpackFiles(from: packed) { p in progress?(0.5 + p * 0.4) }
                progress?(0.9)
                DispatchQueue.main.sync {
                    LLDatabaseManager.shared.reopenDatabase()
                }
                progress?(1.0)
                LLLogger.info("✅ 恢复成功")
                DispatchQueue.main.async { completion(nil) }
            } catch BackupError.invalidFile {
                DispatchQueue.main.async { completion("文件格式不正确，请选择由本软件导出的 .llbak 备份文件") }
            } catch BackupError.decryptionFailed {
                DispatchQueue.main.async { completion("文件解密失败，备份文件可能已损坏") }
            } catch BackupError.unsupportedVersion {
                DispatchQueue.main.async { completion("备份文件版本不支持，请使用最新版本的软件") }
            } catch {
                LLLogger.error("❌ 恢复失败：\(error)")
                DispatchQueue.main.async { completion("恢复失败：\(error.localizedDescription)") }
            }
        }
    }

    // MARK: - 打包 / 解包

    // 格式：[文件数(4B大端)] + N×[路径长(2B大端)+路径(UTF-8)+数据长(8B大端)+数据]
    private func packFiles(progress: ((Double) -> Void)? = nil) throws -> Data {
        let fm = FileManager.default
        var items: [(path: String, data: Data)] = []
        for rel in filesToBackup {
            let url = documentsURL.appendingPathComponent(rel)
            guard fm.fileExists(atPath: url.path), let data = try? Data(contentsOf: url) else { continue }
            items.append((rel, data))
            LLLogger.info("📦 打包：\(rel) (\(data.count / 1024) KB)")
        }
        var result = Data()
        var count = UInt32(items.count).bigEndian
        withUnsafeBytes(of: &count) { result.append(contentsOf: $0) }
        for (i, item) in items.enumerated() {
            let pathBytes = item.path.data(using: .utf8)!
            var pathLen = UInt16(pathBytes.count).bigEndian
            withUnsafeBytes(of: &pathLen) { result.append(contentsOf: $0) }
            result.append(pathBytes)
            var dataLen = UInt64(item.data.count).bigEndian
            withUnsafeBytes(of: &dataLen) { result.append(contentsOf: $0) }
            result.append(item.data)
            progress?(Double(i + 1) / Double(items.count))
        }
        return result
    }

    private func unpackFiles(from data: Data, progress: ((Double) -> Void)? = nil) throws {
        let fm = FileManager.default
        var offset = 0

        func read(_ n: Int) throws -> Data {
            guard offset + n <= data.count else { throw BackupError.invalidFile }
            let s = data.subdata(in: offset..<offset + n)
            offset += n
            return s
        }

        let countBytes = try read(4)
        let fileCount = Int(UInt32(bigEndian: countBytes.withUnsafeBytes { $0.load(as: UInt32.self) }))

        for i in 0..<fileCount {
            let pathLenBytes = try read(2)
            let pathLen = Int(UInt16(bigEndian: pathLenBytes.withUnsafeBytes { $0.load(as: UInt16.self) }))
            let pathData = try read(pathLen)
            guard let relativePath = String(data: pathData, encoding: .utf8) else { throw BackupError.invalidFile }
            let dataLenBytes = try read(8)
            let dataLen = Int(UInt64(bigEndian: dataLenBytes.withUnsafeBytes { $0.load(as: UInt64.self) }))
            let fileData = try read(dataLen)

            let destURL = documentsURL.appendingPathComponent(relativePath)
            try fm.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if fm.fileExists(atPath: destURL.path) { try fm.removeItem(at: destURL) }
            try fileData.write(to: destURL)
            LLLogger.info("📂 恢复：\(relativePath) (\(dataLen / 1024) KB)")
            progress?(Double(i + 1) / Double(fileCount))
        }
    }

    // MARK: - 加密 / 解密

    private func encrypt(_ data: Data) throws -> Data {
        do {
            let box = try AES.GCM.seal(data, using: symmetricKey)
            guard let combined = box.combined else { throw BackupError.decryptionFailed }
            return combined
        } catch {
            throw BackupError.decryptionFailed
        }
    }

    private func decrypt(_ data: Data) throws -> Data {
        do {
            let box = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(box, using: symmetricKey)
        } catch {
            throw BackupError.decryptionFailed
        }
    }

    // MARK: - 文件头构建 / 解析

    // 文件头格式：[魔数(4B)] + [版本(1B)] + [加密数据长度(8B大端)] + [加密数据]
    private func buildFileData(_ encrypted: Data) -> Data {
        var result = Data()
        result.append(contentsOf: LLBackupManager.magic)
        result.append(LLBackupManager.formatVersion)
        var len = UInt64(encrypted.count).bigEndian
        withUnsafeBytes(of: &len) { result.append(contentsOf: $0) }
        result.append(encrypted)
        return result
    }

    private func parseFileData(_ data: Data) throws -> Data {
        var offset = 0

        func read(_ n: Int) throws -> Data {
            guard offset + n <= data.count else { throw BackupError.invalidFile }
            let s = data.subdata(in: offset..<offset + n)
            offset += n
            return s
        }

        // 校验魔数
        let magicBytes = try read(4)
        let expectedMagic = Data(LLBackupManager.magic)
        guard magicBytes == expectedMagic else { throw BackupError.invalidFile }

        // 校验版本
        let versionByte = try read(1)
        let version = versionByte[versionByte.startIndex]
        guard version == LLBackupManager.formatVersion else { throw BackupError.unsupportedVersion }

        // 读取加密数据长度
        let lenBytes = try read(8)
        let encLen = Int(UInt64(bigEndian: lenBytes.withUnsafeBytes { $0.load(as: UInt64.self) }))

        // 读取加密数据
        let encData = try read(encLen)
        return encData
    }
}
