//
//  LLSpeechService.swift
//  LearnLanguage
//
//  文字转语音服务（离线，基于 AVSpeechSynthesizer，参考 TranslateP/SpeechManager）
//

import AVFoundation

final class LLSpeechService: NSObject {

    static let shared = LLSpeechService()

    // MARK: - Properties

    private let synthesizer = AVSpeechSynthesizer()
    private let speechQueue = DispatchQueue(label: "com.learnlanguage.speech", qos: .userInitiated)

    private(set) var isSpeaking = false

    /// 朗读完成回调
    var onDidFinish: (() -> Void)?

    // MARK: - Init

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public Methods

    /// 朗读文字
    /// - Parameters:
    ///   - text: 要朗读的文字
    ///   - language: 语言代码，默认英文 "en-US"，中文传 "zh-CN"
    func speak(_ text: String, language: String = "en-US") {
        guard !text.isEmpty else { return }

        if synthesizer.isSpeaking {
            stop()
            return
        }

        speechQueue.async { [weak self] in
            guard let self else { return }
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: language)
            utterance.rate = 0.5
            utterance.volume = 1.0

            DispatchQueue.main.async { self.isSpeaking = true }
            self.synthesizer.speak(utterance)
        }
    }

    /// 停止朗读
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension LLSpeechService: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
            self?.onDidFinish?()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
        }
    }
}
