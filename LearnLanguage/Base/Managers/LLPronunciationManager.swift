//
//  LLPronunciationManager.swift
//  LearnLanguage
//
//  语音发音管理器 - 支持多种发音提供者

import Foundation
import AVFoundation
import AppKit

// MARK: - 发音提供者协议

/// 发音提供者协议，所有发音实现都需要遵循此协议
protocol LLPronunciationProviderProtocol {
    /// 播放单词发音
    /// - Parameters:
    ///   - word: 要发音的单词
    ///   - accent: 口音类型（美式/英式）
    ///   - rate: 语速 (0.0-1.0)
    ///   - completion: 完成回调
    func speak(word: String, accent: LLPronunciationAccent, rate: Float, completion: ((Bool, Error?) -> Void)?)
    
    /// 停止当前发音
    func stop()
    
    /// 是否正在发音
    var isSpeaking: Bool { get }
}

// MARK: - 本地 TTS 发音提供者

final class LLLocalPronunciationProvider: NSObject, LLPronunciationProviderProtocol {
    
    private let synthesizer = AVSpeechSynthesizer()
    private var completion: ((Bool, Error?) -> Void)?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(word: String, accent: LLPronunciationAccent, rate: Float, completion: ((Bool, Error?) -> Void)?) {
        // 停止当前发音（在后台线程执行，避免主线程 QoS 优先级反转警告）
        if synthesizer.isSpeaking {
            DispatchQueue.global(qos: .default).async { [weak self] in
                self?.synthesizer.stopSpeaking(at: .immediate)
            }
        }
        
        self.completion = completion
        
        let utterance = AVSpeechUtterance(string: word)
        
        // 设置语言和口音
        let languageCode = accent == .us ? "en-US" : "en-GB"
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        
        // 设置语速（AVSpeechSynthesizer 的范围是 0.0-1.0）
        utterance.rate = rate
        
        // 设置音量和音调
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        
        // 开始发音
        synthesizer.speak(utterance)
        
        LLLogger.debug("🔊 本地发音：\(word) [\(accent.displayName)]")
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            DispatchQueue.global(qos: .default).async { [weak self] in
                self?.synthesizer.stopSpeaking(at: .immediate)
            }
        }
    }
    
    var isSpeaking: Bool {
        return synthesizer.isSpeaking
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension LLLocalPronunciationProvider: AVSpeechSynthesizerDelegate {
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        completion?(true, nil)
        completion = nil
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        completion?(false, nil)
        completion = nil
    }
}

// MARK: - 有道发音提供者

final class LLYoudaoPronunciationProvider: LLPronunciationProviderProtocol {
    
    private var audioPlayer: AVAudioPlayer?
    private var completion: ((Bool, Error?) -> Void)?
    
    func speak(word: String, accent: LLPronunciationAccent, rate: Float, completion: ((Bool, Error?) -> Void)?) {
        self.completion = completion
        
        // 先查缓存
        if let cachedData = LLAudioCacheManager.shared.cachedAudioData(word: word, provider: .youdao, accent: accent) {
            playAudioData(cachedData, rate: rate)
            return
        }
        
        // 有道词典音频 URL
        // 美式：http://dict.youdao.com/dictvoice?audio={word}&type=1
        // 英式：http://dict.youdao.com/dictvoice?audio={word}&type=2
        let type = accent == .us ? "1" : "2"
        let urlString = "http://dict.youdao.com/dictvoice?audio=\(word)&type=\(type)"
        
        LLLogger.info("🔊 有道发音 URL：\(urlString)")
        
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else {
            completion?(false, NSError(domain: "LLPronunciation", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 URL"]))
            return
        }
        
        LLLogger.debug("🔊 有道发音：\(word) [\(accent.displayName)] - \(urlString)")
        
        // 使用 URLSession.shared，它会自动处理系统代理
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    LLLogger.error("❌ 播放失败：\(error.localizedDescription)")
                    LLLogger.info("💡 提示：请检查网络连接或代理设置，也可以尝试使用本地发音")
                    self.completion?(false, error)
                    self.completion = nil
                }
                return
            }
            
            // 检查 HTTP 响应状态
            if let httpResponse = response as? HTTPURLResponse {
                LLLogger.debug("📡 HTTP 状态码：\(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    DispatchQueue.main.async {
                        let error = NSError(domain: "LLPronunciation", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "服务器返回错误：\(httpResponse.statusCode)"])
                        LLLogger.error("❌ 播放失败：HTTP \(httpResponse.statusCode)")
                        self.completion?(false, error)
                        self.completion = nil
                    }
                    return
                }
            }
            
            guard let data = data, !data.isEmpty else {
                DispatchQueue.main.async {
                    let error = NSError(domain: "LLPronunciation", code: -2, userInfo: [NSLocalizedDescriptionKey: "无音频数据"])
                    LLLogger.error("❌ 播放失败：无音频数据")
                    self.completion?(false, error)
                    self.completion = nil
                }
                return
            }
            
            LLLogger.debug("📦 收到音频数据：\(data.count) 字节")
            
            // 保存到缓存
            LLAudioCacheManager.shared.saveAudioData(data, word: word, provider: .youdao, accent: accent)
            
            DispatchQueue.main.async {
                self.playAudioData(data, rate: rate)
            }
        }.resume()
    }
    
    /// 播放音频数据
    private func playAudioData(_ data: Data, rate: Float) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true
            audioPlayer?.rate = rate
            
            let success = audioPlayer?.play() ?? false
            if success {
                LLLogger.info("✅ 播放成功")
            } else {
                LLLogger.error("❌ 播放失败：无法启动播放器")
            }
            completion?(success, success ? nil : NSError(domain: "LLPronunciation", code: -3, userInfo: [NSLocalizedDescriptionKey: "播放器启动失败"]))
            completion = nil
        } catch {
            LLLogger.error("❌ 播放失败：\(error.localizedDescription)")
            completion?(false, error)
            completion = nil
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    var isSpeaking: Bool {
        return audioPlayer?.isPlaying ?? false
    }
}

// MARK: - Google TTS 发音提供者（预留）

final class LLGooglePronunciationProvider: LLPronunciationProviderProtocol {
    
    func speak(word: String, accent: LLPronunciationAccent, rate: Float, completion: ((Bool, Error?) -> Void)?) {
        // TODO: 实现 Google TTS
        LLLogger.info("🔊 Google 发音：\(word) [\(accent.displayName)] - 待实现")
        completion?(false, NSError(domain: "LLPronunciation", code: -999, userInfo: [NSLocalizedDescriptionKey: "Google TTS 尚未实现"]))
    }
    
    func stop() {
        // TODO: 实现停止逻辑
    }
    
    var isSpeaking: Bool {
        return false
    }
}

// MARK: - Azure Speech 发音提供者（预留）

final class LLAzurePronunciationProvider: LLPronunciationProviderProtocol {
    
    func speak(word: String, accent: LLPronunciationAccent, rate: Float, completion: ((Bool, Error?) -> Void)?) {
        // TODO: 实现 Azure Speech
        LLLogger.info("🔊 Azure 发音：\(word) [\(accent.displayName)] - 待实现")
        completion?(false, NSError(domain: "LLPronunciation", code: -999, userInfo: [NSLocalizedDescriptionKey: "Azure Speech 尚未实现"]))
    }
    
    func stop() {
        // TODO: 实现停止逻辑
    }
    
    var isSpeaking: Bool {
        return false
    }
}

// MARK: - 发音管理器

final class LLPronunciationManager {
    
    static let shared = LLPronunciationManager()
    
    // 所有发音提供者
    private var providers: [LLPronunciationProvider: LLPronunciationProviderProtocol] = [:]
    
    // 当前使用的提供者
    private var currentProvider: LLPronunciationProviderProtocol?
    
    private init() {
        // 初始化所有提供者
        providers[.local] = LLLocalPronunciationProvider()
        providers[.youdao] = LLYoudaoPronunciationProvider()
        providers[.google] = LLGooglePronunciationProvider()
        providers[.azure] = LLAzurePronunciationProvider()
        
        // 设置当前提供者
        updateCurrentProvider()
    }
    
    /// 更新当前提供者（根据设置）
    private func updateCurrentProvider() {
        let settings = LLSettingsStore.shared.settings
        currentProvider = providers[settings.pronunciationProvider]
    }
    
    /// 播放单词发音（使用当前设置）
    /// - Parameters:
    ///   - word: 要发音的单词
    ///   - completion: 完成回调
    func speak(word: String, completion: ((Bool, Error?) -> Void)? = nil) {
        let settings = LLSettingsStore.shared.settings
        
        // 检查是否启用发音
        guard settings.pronunciationEnabled else {
            LLLogger.warn("⚠️ 发音功能已禁用")
            completion?(false, NSError(domain: "LLPronunciation", code: -100, userInfo: [NSLocalizedDescriptionKey: "发音功能已禁用"]))
            return
        }
        
        // 更新当前提供者
        updateCurrentProvider()
        
        // 使用当前提供者播放
        currentProvider?.speak(
            word: word,
            accent: settings.pronunciationAccent,
            rate: settings.pronunciationRate,
            completion: completion
        )
    }
    
    /// 播放单词发音（指定口音）
    /// - Parameters:
    ///   - word: 要发音的单词
    ///   - accent: 口音类型
    ///   - completion: 完成回调
    func speak(word: String, accent: LLPronunciationAccent, completion: ((Bool, Error?) -> Void)? = nil) {
        let settings = LLSettingsStore.shared.settings
        
        guard settings.pronunciationEnabled else {
            LLLogger.warn("⚠️ 发音功能已禁用")
            completion?(false, NSError(domain: "LLPronunciation", code: -100, userInfo: [NSLocalizedDescriptionKey: "发音功能已禁用"]))
            return
        }
        
        updateCurrentProvider()
        
        currentProvider?.speak(
            word: word,
            accent: accent,
            rate: settings.pronunciationRate,
            completion: completion
        )
    }
    
    /// 播放单词发音（完全自定义）
    /// - Parameters:
    ///   - word: 要发音的单词
    ///   - provider: 发音提供者
    ///   - accent: 口音类型
    ///   - rate: 语速
    ///   - completion: 完成回调
    func speak(word: String, provider: LLPronunciationProvider, accent: LLPronunciationAccent, rate: Float, completion: ((Bool, Error?) -> Void)? = nil) {
        providers[provider]?.speak(word: word, accent: accent, rate: rate, completion: completion)
    }
    
    /// 停止当前发音
    func stop() {
        currentProvider?.stop()
    }
    
    /// 是否正在发音
    var isSpeaking: Bool {
        return currentProvider?.isSpeaking ?? false
    }
    
    /// 获取可用的发音提供者列表
    func availableProviders() -> [LLPronunciationProvider] {
        return Array(providers.keys)
    }
    
    /// 测试发音提供者是否可用
    /// - Parameter provider: 发音提供者
    /// - Returns: 是否可用
    func testProvider(_ provider: LLPronunciationProvider, completion: @escaping (Bool) -> Void) {
        providers[provider]?.speak(word: "test", accent: .us, rate: 0.5) { success, error in
            if let error = error {
                LLLogger.error("❌ 测试 \(provider.displayName) 失败：\(error.localizedDescription)")
            }
            completion(success)
        }
    }
}

