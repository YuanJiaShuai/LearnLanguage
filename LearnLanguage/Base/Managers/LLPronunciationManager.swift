//
//  LLPronunciationManager.swift
//  LearnLanguage
//
//  语音发音管理器 - 支持多种发音提供者

import Foundation
import AVFoundation
import AppKit

private extension Float {
    var llClampedAudioVolume: Float { min(max(self, 0), 1) }
}

private struct LLChineseMeaningSpeechNormalizer {
    
    private static let partOfSpeechReplacements: [(tokens: [String], text: String)] = [
        (["adj.", "a."], "形容词，"),
        (["adv."], "副词，"),
        (["n."], "名词，"),
        (["v."], "动词，"),
        (["vt."], "及物动词，"),
        (["vi."], "不及物动词，"),
        (["prep."], "介词，"),
        (["pron."], "代词，"),
        (["conj."], "连词，"),
        (["interj.", "int."], "感叹词，"),
        (["aux."], "助动词，"),
        (["num."], "数词，"),
        (["art."], "冠词，"),
        (["abbr."], "缩写，"),
        (["pl."], "复数，"),
        (["sing."], "单数，"),
        (["phr."], "短语，"),
        (["idiom."], "习语，")
    ]
    
    static func normalize(_ meaning: String) -> String {
        var text = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        text = replacePartOfSpeech(in: text)
        
        let punctuationReplacements: [(String, String)] = [
            ("\n", "，"),
            ("\r", "，"),
            (";", "，"),
            ("；", "，"),
            (",", "，"),
            ("/", "，"),
            ("、", "，")
        ]
        for (source, target) in punctuationReplacements {
            text = text.replacingOccurrences(of: source, with: target)
        }
        
        text = text.replacingOccurrences(
            of: "\\s+",
            with: " ",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "，\\s*，+",
            with: "，",
            options: .regularExpression
        )
        text = text.replacingOccurrences(
            of: "\\s*，\\s*",
            with: "，",
            options: .regularExpression
        )
        
        return text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "，")))
    }
    
    private static func replacePartOfSpeech(in text: String) -> String {
        var result = text
        for replacement in partOfSpeechReplacements {
            for token in replacement.tokens {
                result = replaceToken(token, with: replacement.text, in: result)
            }
        }
        return result
    }
    
    private static func replaceToken(_ token: String, with replacement: String, in text: String) -> String {
        let escapedToken = NSRegularExpression.escapedPattern(for: token)
        let pattern = "(?i)(^|[\\s\\n\\r,，;；/\\(\\[（【])\(escapedToken)(?=$|[^A-Za-z0-9])"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        let matches = regex.matches(in: text, range: nsRange)
        guard !matches.isEmpty else { return text }
        
        var result = text
        for match in matches.reversed() {
            guard
                let fullRange = Range(match.range(at: 0), in: result),
                let prefixRange = Range(match.range(at: 1), in: result)
            else { continue }
            
            let prefix = String(result[prefixRange])
            result.replaceSubrange(fullRange, with: prefix + replacement)
        }
        return result
    }
}

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
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        self.completion = completion
        
        let utterance = AVSpeechUtterance(string: word)
        
        // 设置语言和口音
        let languageCode = accent == .us ? "en-US" : "en-GB"
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        
        // 临时固定本地发音语速为 0.5（保留原设置参数代码，后续可恢复）
        // utterance.rate = rate
        utterance.rate = 0.5
        
        // 设置音量和音调
        let appAudioVolume = LLSettingsStore.shared.settings.appAudioVolume.llClampedAudioVolume
        utterance.volume = appAudioVolume
        utterance.pitchMultiplier = 1.0
        
        // 开始发音
        synthesizer.speak(utterance)
        
        LLLogger.debug("🔊 本地发音：\(word) [\(accent.displayName)]")
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
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

final class LLYoudaoPronunciationProvider: NSObject, LLPronunciationProviderProtocol, AVAudioPlayerDelegate {
    
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
            completion?(false, NSError(domain: "LLPronunciation", code: -1, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Invalid URL", comment: "Invalid URL error")]))
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
                        let error = NSError(domain: "LLPronunciation", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: String(format: NSLocalizedString("Server Error", comment: "Server error message"), httpResponse.statusCode)])
                        LLLogger.error("❌ 播放失败：HTTP \(httpResponse.statusCode)")
                        self.completion?(false, error)
                        self.completion = nil
                    }
                    return
                }
            }
            
            guard let data = data, !data.isEmpty else {
                DispatchQueue.main.async {
                    let error = NSError(domain: "LLPronunciation", code: -2, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("No Audio Data", comment: "No audio data error")])
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
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true
            audioPlayer?.rate = rate
            audioPlayer?.volume = LLSettingsStore.shared.settings.appAudioVolume.llClampedAudioVolume
            
            let success = audioPlayer?.play() ?? false
            if success {
                LLLogger.info("✅ 播放成功")
                return
            } else {
                LLLogger.error("❌ 播放失败：无法启动播放器")
            }
            completion?(success, success ? nil : NSError(domain: "LLPronunciation", code: -3, userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Player Start Failed", comment: "Player startup failed error")]))
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
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        completion?(flag, nil)
        completion = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        completion?(false, error)
        completion = nil
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
    private static let chineseAfterEnglishDelay: TimeInterval = 0.12
    
    // 所有发音提供者
    private var providers: [LLPronunciationProvider: LLPronunciationProviderProtocol] = [:]
    
    // 当前使用的提供者
    private var currentProvider: LLPronunciationProviderProtocol?
    
    private init() {
        // 初始化所有提供者
        providers[.local] = LLLocalPronunciationProvider()
        providers[.youdao] = LLYoudaoPronunciationProvider()
        // providers[.google] = LLGooglePronunciationProvider()
        // providers[.azure] = LLAzurePronunciationProvider()
        
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
        
        speakEnglishWord(word, accent: settings.pronunciationAccent, rate: settings.pronunciationRate, completion: completion)
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
        
        speakEnglishWord(word, accent: accent, rate: settings.pronunciationRate, completion: completion)
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
    
    /// 手动播放英文单词发音，不受英文/中文/随机朗读开关影响
    func speakEnglishManually(word: String, completion: ((Bool, Error?) -> Void)? = nil) {
        let text = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            completion?(false, NSError(domain: "LLPronunciation", code: -103, userInfo: [NSLocalizedDescriptionKey: "单词为空"]))
            return
        }
        
        stop()
        let settings = LLSettingsStore.shared.settings
        speakEnglishWord(
            text,
            accent: settings.pronunciationAccent,
            rate: settings.pronunciationRate,
            completion: completion
        )
    }
    
    /// 根据朗读模式播放学习项：英文、中文释义、或随机二选一
    func speak(entry: LLWordEntry, completion: ((Bool, Error?) -> Void)? = nil) {
        let settings = LLSettingsStore.shared.settings
        let shouldSpeakEnglish = settings.pronunciationEnabled
        let shouldSpeakChinese = settings.chineseMeaningPronunciationEnabled
        stop()
        
        if settings.randomPronunciationEnabled {
            if Bool.random() {
                speakEnglishWord(
                    entry.text,
                    accent: settings.pronunciationAccent,
                    rate: settings.pronunciationRate,
                    completion: completion
                )
            } else {
                speakChineseMeaning(entry.meaning, completion: completion)
            }
            return
        }
        
        switch (shouldSpeakEnglish, shouldSpeakChinese) {
        case (true, true):
            speakEnglishWord(entry.text, accent: settings.pronunciationAccent, rate: settings.pronunciationRate) { [weak self] success, error in
                guard success else {
                    completion?(success, error)
                    return
                }
                self?.speakChineseMeaningAfterEnglishStops(entry.meaning, completion: completion)
            }
        case (true, false):
            speakEnglishWord(entry.text, accent: settings.pronunciationAccent, rate: settings.pronunciationRate, completion: completion)
        case (false, true):
            speakChineseMeaning(entry.meaning, completion: completion)
        case (false, false):
            completion?(false, NSError(domain: "LLPronunciation", code: -101, userInfo: [NSLocalizedDescriptionKey: "朗读功能未启用"]))
        }
    }
    
    /// 原生朗读中文释义
    func speakChineseMeaning(_ meaning: String, completion: ((Bool, Error?) -> Void)? = nil) {
        let text = LLChineseMeaningSpeechNormalizer.normalize(meaning)
        guard !text.isEmpty else {
            completion?(false, NSError(domain: "LLPronunciation", code: -102, userInfo: [NSLocalizedDescriptionKey: "中文释义为空"]))
            return
        }
        LLLogger.debug("🔊 中文释义朗读：\(text)")
        
        LLSpeechService.shared.onDidFinish = {
            completion?(true, nil)
        }
        
        let didStart = LLSpeechService.shared.speak(text, language: "zh-CN")
        if !didStart {
            completion?(false, nil)
        }
    }
    
    /// 停止当前发音
    func stop() {
        currentProvider?.stop()
        LLSpeechService.shared.stop()
    }
    
    /// 是否正在发音
    var isSpeaking: Bool {
        return (currentProvider?.isSpeaking ?? false) || LLSpeechService.shared.isSpeaking
    }
    
    private func speakEnglishWord(_ word: String, accent: LLPronunciationAccent, rate: Float, completion: ((Bool, Error?) -> Void)? = nil) {
        updateCurrentProvider()
        currentProvider?.speak(
            word: word,
            accent: accent,
            rate: rate,
            completion: completion
        )
    }
    
    private func speakChineseMeaningAfterEnglishStops(_ meaning: String, completion: ((Bool, Error?) -> Void)? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.chineseAfterEnglishDelay) { [weak self] in
            guard let self else { return }
            if self.currentProvider?.isSpeaking == true {
                self.speakChineseMeaningAfterEnglishStops(meaning, completion: completion)
                return
            }
            self.speakChineseMeaning(meaning, completion: completion)
        }
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
