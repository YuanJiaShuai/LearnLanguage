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
    private var speechGeneration = 0
    private var currentUtterance: AVSpeechUtterance?

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
    ///   - rate: 语速
    @discardableResult
    func speak(_ text: String, language: String = "en-US", rate: Float = 0.5) -> Bool {
        guard !text.isEmpty else { return false }

        if synthesizer.isSpeaking {
            stop()
            return false
        }
        
        speechGeneration += 1
        let generation = speechGeneration

        speechQueue.async { [weak self] in
            guard let self else { return }
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: language)
            utterance.rate = rate
            utterance.volume = min(max(LLSettingsStore.shared.settings.appAudioVolume, 0), 1)

            DispatchQueue.main.async {
                guard self.isCurrentSpeech(generation) else { return }
                self.currentUtterance = utterance
                self.isSpeaking = true
                self.synthesizer.speak(utterance)
            }
        }
        
        return true
    }

    /// 停止朗读
    func stop() {
        speechGeneration += 1
        synthesizer.stopSpeaking(at: .immediate)
        DispatchQueue.main.async { [weak self] in
            self?.isSpeaking = false
            self?.currentUtterance = nil
        }
    }
    
    private func isCurrentSpeech(_ generation: Int) -> Bool {
        speechGeneration == generation
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension LLSpeechService: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self, utterance === self.currentUtterance else { return }
            self.isSpeaking = false
            self.currentUtterance = nil
            self.onDidFinish?()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [weak self] in
            guard let self, utterance === self.currentUtterance else { return }
            self.isSpeaking = false
            self.currentUtterance = nil
        }
    }
}
