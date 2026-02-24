//
//  LLTypingDisplayView.swift
//  LearnLanguage
//
//  单词显示视图 - 使用 NSAttributedString 实现高亮效果
//  完全重构，不再使用多个字母视图，性能更优
//

import AppKit
import SnapKit

/// 单词显示视图
class LLTypingDisplayView: NSView {
    
    // MARK: - Properties
    
    private let textField = NSTextField()
    private var engine: LLTypingEngine
    
    // MARK: - Initialization
    
    init(word: String) {
        self.engine = LLTypingEngine(targetWord: word)
        super.init(frame: .zero)
        setupUI()
        updateDisplay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        
        // 配置文本框
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.isSelectable = false
        textField.alignment = .center
        textField.font = NSFont.monospacedSystemFont(ofSize: 48, weight: .regular)
        
        addSubview(textField)
        textField.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(20)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }
    }
    
    // MARK: - Public Methods
    
    /// 处理输入字符
    /// - Parameter char: 输入的字符
    /// - Returns: 是否正确
    func handleInput(_ char: Character) -> Bool {
        let isCorrect = engine.input(char: char)
        updateDisplay()
        
        if !isCorrect {
            playShakeAnimation()
        }
        
        return isCorrect
    }
    
    /// 重置为新单词
    func reset(word: String) {
        engine.reset(newWord: word)
        updateDisplay()
    }
    
    /// 重新开始当前单词
    func restart() {
        engine.restart()
        updateDisplay()
    }
    
    /// 获取引擎状态（供外部读取）
    var isFinished: Bool {
        return engine.isFinished
    }
    
    var errorCount: Int {
        return engine.errorCount
    }
    
    var accuracy: Int {
        return engine.accuracy
    }
    
    var speed: Int {
        return engine.speed
    }
    
    var elapsedTime: TimeInterval {
        return engine.elapsedTime
    }
    
    // MARK: - Private Methods
    
    /// 更新显示
    private func updateDisplay() {
        let attributedString = NSMutableAttributedString()
        
        // 1. 已输入的部分（绿色）
        let typedPart = NSAttributedString(
            string: engine.typedPrefix,
            attributes: [
                .foregroundColor: NSColor.systemGreen,
                .font: NSFont.monospacedSystemFont(ofSize: 48, weight: .regular)
            ]
        )
        attributedString.append(typedPart)
        
        // 2. 当前字符（高亮 + 下划线）
        if !engine.isFinished, let firstChar = engine.remainingSuffix.first {
            let currentColor = engine.lastInputWasError ? NSColor.white : NSColor.systemBlue
            let backgroundColor = engine.lastInputWasError ? NSColor.systemRed : NSColor.clear
            
            let currentChar = NSAttributedString(
                string: String(firstChar),
                attributes: [
                    .foregroundColor: currentColor,
                    .backgroundColor: backgroundColor,
                    .underlineStyle: NSUnderlineStyle.thick.rawValue,
                    .underlineColor: NSColor.systemBlue,
                    .font: NSFont.monospacedSystemFont(ofSize: 48, weight: .regular)
                ]
            )
            attributedString.append(currentChar)
            
            // 3. 剩余部分（灰色）
            let remainingPart = NSAttributedString(
                string: String(engine.remainingSuffix.dropFirst()),
                attributes: [
                    .foregroundColor: NSColor.gray.withAlphaComponent(0.3),
                    .font: NSFont.monospacedSystemFont(ofSize: 48, weight: .regular)
                ]
            )
            attributedString.append(remainingPart)
        }
        
        textField.attributedStringValue = attributedString
    }
    
    /// 播放抖动动画
    private func playShakeAnimation() {
        guard let layer = layer else { return }
        
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.4
        animation.values = [-8, 8, -6, 6, -4, 4, -2, 2, 0]
        
        layer.add(animation, forKey: "shake")
    }
}

