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
    private var wrongPlayer: AVAudioPlayer?
    private var completeSound: NSSound?
    private var wrongSound: NSSound?
    private var letterPlayers: [Character: AVAudioPlayer] = [:]
    
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
        
        wrongSound = NSSound(named: "Basso")
        completeSound = NSSound(named: "Glass")
        preloadLetterSounds()
    }
    
    private func preloadLetterSounds() {
        for scalar in UnicodeScalar("a").value...UnicodeScalar("z").value {
            guard let unicodeScalar = UnicodeScalar(scalar) else { continue }
            let letter = Character(unicodeScalar)
            let resourceName = "ll_\(letter)"
            
            guard let url = Bundle.main.url(forResource: resourceName, withExtension: "mp3") else {
                LLLogger.warn("⚠️ 未找到字母音频文件 \(resourceName).mp3")
                continue
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                letterPlayers[letter] = player
            } catch {
                LLLogger.error("❌ 加载字母音频失败：\(resourceName).mp3 - \(error)")
            }
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
    
    /// 播放字母音效
    func playLetterSound(for char: Character) {
        guard isEnabled else { return }
        let lowercased = Character(String(char).lowercased())
        guard lowercased >= "a" && lowercased <= "z" else { return }
        guard let player = letterPlayers[lowercased] else {
            LLLogger.warn("⚠️ 未找到字母音频播放器：\(lowercased)")
            return
        }
        
        player.currentTime = 0
        player.play()
    }
    
    /// 播放错误音效
    func playWrongSound() {
        guard isEnabled else { return }
        wrongSound?.play()
    }
    
    /// 播放完成音效
    func playCompleteSound() {
        guard isEnabled else { return }
        completeSound?.play()
    }
}
