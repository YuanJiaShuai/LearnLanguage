//
//  LLAudioCacheManager.swift
//  LearnLanguage
//
//  音频缓存管理器 - 缓存网络发音数据到本地文件系统
//  支持多发音提供者（有道、Google、Azure 等）和多口音（美式/英式）
//

import Foundation

final class LLAudioCacheManager {
    
    static let shared = LLAudioCacheManager()
    
    // MARK: - Constants
    
    /// 最大缓存大小：200MB
    private let maxCacheSizeBytes: Int64 = 200 * 1024 * 1024
    
    // MARK: - Properties
    
    /// 缓存根目录：~/Library/Application Support/LearnLanguage/AudioCache/
    private let cacheRootURL: URL
    
    private let fileManager = FileManager.default
    
    // MARK: - Init
    
    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        cacheRootURL = appSupport
            .appendingPathComponent("LearnLanguage", isDirectory: true)
            .appendingPathComponent("AudioCache", isDirectory: true)
        
        createCacheDirectoryIfNeeded()
        
        LLLogger.info("🎵 音频缓存目录：\(cacheRootURL.path)")
    }
    
    // MARK: - Public Methods
    
    /// 获取音频数据（先查缓存，没有则返回 nil）
    /// - Parameters:
    ///   - word: 单词
    ///   - provider: 发音提供者
    ///   - accent: 口音
    /// - Returns: 缓存的音频数据，如果没有缓存则返回 nil
    func cachedAudioData(word: String, provider: LLPronunciationProvider, accent: LLPronunciationAccent) -> Data? {
        let fileURL = cacheFileURL(word: word, provider: provider, accent: accent)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            LLLogger.debug("🎵 命中缓存：\(word) [\(provider.rawValue)/\(accent.rawValue)]")
            return data
        } catch {
            LLLogger.error("❌ 读取缓存失败：\(word) - \(error)")
            return nil
        }
    }
    
    /// 保存音频数据到缓存
    /// - Parameters:
    ///   - data: 音频数据
    ///   - word: 单词
    ///   - provider: 发音提供者
    ///   - accent: 口音
    func saveAudioData(_ data: Data, word: String, provider: LLPronunciationProvider, accent: LLPronunciationAccent) {
        let fileURL = cacheFileURL(word: word, provider: provider, accent: accent)
        
        // 确保子目录存在
        let directory = fileURL.deletingLastPathComponent()
        createDirectoryIfNeeded(at: directory)
        
        do {
            try data.write(to: fileURL, options: .atomic)
            LLLogger.debug("🎵 已缓存：\(word) [\(provider.rawValue)/\(accent.rawValue)] (\(data.count / 1024)KB)")
            
            // 异步检查缓存大小
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.evictIfNeeded()
            }
        } catch {
            LLLogger.error("❌ 缓存保存失败：\(word) - \(error)")
        }
    }
    
    /// 检查是否有缓存
    func hasCached(word: String, provider: LLPronunciationProvider, accent: LLPronunciationAccent) -> Bool {
        let fileURL = cacheFileURL(word: word, provider: provider, accent: accent)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// 删除指定单词的所有缓存（所有提供者、所有口音）
    func removeCache(for word: String) {
        for provider in LLPronunciationProvider.allCases {
            for accent in LLPronunciationAccent.allCases {
                let fileURL = cacheFileURL(word: word, provider: provider, accent: accent)
                try? fileManager.removeItem(at: fileURL)
            }
        }
        LLLogger.info("🗑️ 已清除单词缓存：\(word)")
    }
    
    /// 清除所有缓存
    func clearAllCache() {
        do {
            try fileManager.removeItem(at: cacheRootURL)
            createCacheDirectoryIfNeeded()
            LLLogger.info("🗑️ 已清除所有音频缓存")
        } catch {
            LLLogger.error("❌ 清除缓存失败：\(error)")
        }
    }
    
    /// 获取当前缓存大小（字节）
    var cacheSizeBytes: Int64 {
        return directorySize(at: cacheRootURL)
    }
    
    /// 获取当前缓存大小（格式化字符串）
    var cacheSizeString: String {
        let bytes = cacheSizeBytes
        if bytes < 1024 {
            return "\(bytes) B"
        } else if bytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(bytes) / 1024)
        } else {
            return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
        }
    }
    
    // MARK: - Private Methods
    
    /// 生成缓存文件 URL
    /// 目录结构：AudioCache/{provider}/{accent}/{word}.mp3
    /// 例如：AudioCache/youdao/us/apple.mp3
    private func cacheFileURL(word: String, provider: LLPronunciationProvider, accent: LLPronunciationAccent) -> URL {
        // 对单词进行安全处理（避免特殊字符导致文件名问题）
        let safeWord = word
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.union(.init(charactersIn: "-_")).inverted)
            .joined(separator: "_")
        
        return cacheRootURL
            .appendingPathComponent(provider.rawValue, isDirectory: true)
            .appendingPathComponent(accent.rawValue, isDirectory: true)
            .appendingPathComponent("\(safeWord).mp3")
    }
    
    /// 创建缓存根目录
    private func createCacheDirectoryIfNeeded() {
        createDirectoryIfNeeded(at: cacheRootURL)
    }
    
    /// 创建目录（如果不存在）
    private func createDirectoryIfNeeded(at url: URL) {
        guard !fileManager.fileExists(atPath: url.path) else { return }
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            LLLogger.error("❌ 创建目录失败：\(url.path) - \(error)")
        }
    }
    
    /// 计算目录大小
    private func directorySize(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else { return 0 }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            totalSize += Int64(size)
        }
        return totalSize
    }
    
    /// 超出最大缓存时，删除最旧的文件
    private func evictIfNeeded() {
        guard cacheSizeBytes > maxCacheSizeBytes else { return }
        
        LLLogger.info("🧹 缓存超出限制（\(cacheSizeString)），开始清理...")
        
        // 收集所有缓存文件及其修改时间
        guard let enumerator = fileManager.enumerator(
            at: cacheRootURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }
        
        var files: [(url: URL, date: Date, size: Int64)] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "mp3" else { continue }
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
            let date = values?.contentModificationDate ?? Date.distantPast
            let size = Int64(values?.fileSize ?? 0)
            files.append((url: fileURL, date: date, size: size))
        }
        
        // 按修改时间升序排序（最旧的排在前面）
        files.sort { $0.date < $1.date }
        
        // 删除旧文件直到缓存大小降到限制的 80%
        let targetSize = Int64(Double(maxCacheSizeBytes) * 0.8)
        var currentSize = cacheSizeBytes
        var deletedCount = 0
        
        for file in files {
            guard currentSize > targetSize else { break }
            do {
                try fileManager.removeItem(at: file.url)
                currentSize -= file.size
                deletedCount += 1
            } catch {
                LLLogger.error("❌ 删除缓存文件失败：\(file.url.lastPathComponent)")
            }
        }
        
        LLLogger.info("🧹 缓存清理完成：删除 \(deletedCount) 个文件，当前大小 \(cacheSizeString)")
    }
}
