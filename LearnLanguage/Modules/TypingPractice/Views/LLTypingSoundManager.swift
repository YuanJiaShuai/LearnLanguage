//
//  LLTypingSoundManager.swift
//  LearnLanguage
//
//  打字音效管理器

import AVFoundation
import AppKit

/// 打字音效管理器
class LLTypingSoundManager {
    
    static let shared = LLTypingSoundManager()
    
    // MARK: - Properties
    
    private var keyPlayer: AVAudioPlayer?
    private var correctPlayer: AVAudioPlayer?
    private var wrongPlayer: AVAudioPlayer?
    
    private var isEnabled: Bool = true
    
    // MARK: - Initialization
    
    private init() {
        setupSounds()
    }
    
    // MARK: - Setup
    
    private func setupSounds() {
        if let url = Bundle.main.url(forResource: "click", withExtension: "wav") {
            do {
                keyPlayer = try AVAudioPlayer(contentsOf: url)
                keyPlayer?.prepareToPlay()
            } catch {
                LLLogger.error("❌ 加载按键音效失败：\(error)")
            }
        } else {
            LLLogger.warn("⚠️ 未找到按键音效文件 click.wav")
        }
    }
    
    // MARK: - Public Methods
    
    /// 启用/禁用音效
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    /// 播放按键音效
    func playKeySound() {
        guard isEnabled else { return }
        guard let keyPlayer = keyPlayer else { return }
        keyPlayer.currentTime = 0
        keyPlayer.play()
    }
    
    /// 播放正确音效
    func playCorrectSound() {
        guard isEnabled else { return }
        // 使用系统音效
        if let sound = NSSound(named: "Tink") {
            sound.play()
        }
    }
    
    /// 播放错误音效
    func playWrongSound() {
        guard isEnabled else { return }
        // 使用系统音效
        if let sound = NSSound(named: "Basso") {
            sound.play()
        }
    }
    
    /// 播放完成音效
    func playCompleteSound() {
        guard isEnabled else { return }
        if let sound = NSSound(named: "Glass") {
            sound.play()
        }
    }
}

