//
//  LLTypingDisplayView.swift
//  LearnLanguage
//
//  单词显示视图 - 使用独立的字母视图和下划线视图
//  支持听写模式（隐藏文字但显示下划线）
//

import AppKit
import SnapKit

/// 单词显示视图
class LLTypingDisplayView: NSView {
    
    // MARK: - Properties
    
    private let containerView = NSView()
    private var letterViews: [LetterView] = []
    private var engine: LLTypingEngine
    
    // MARK: - Initialization
    
    init(word: String) {
        self.engine = LLTypingEngine(targetWord: word)
        super.init(frame: .zero)
        setupUI()
        createLetterViews()
        updateDisplay()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func createLetterViews() {
        // 清空旧的视图
        letterViews.forEach { $0.removeFromSuperview() }
        letterViews.removeAll()
        
        let settings = LLSettingsStore.shared.settings
        let inputStyle = settings.typingInputStyle
        
        let targetChars = Array(engine.targetWord)
        
        for (index, char) in targetChars.enumerated() {
            let letterView = LetterView(
                char: char,
                spacing: inputStyle == .perLetter ? 8 : 0
            )
            containerView.addSubview(letterView)
            letterViews.append(letterView)
            
            // 布局
            if index == 0 {
                letterView.snp.makeConstraints { make in
                    make.leading.equalToSuperview()
                    make.top.bottom.equalToSuperview()
                }
            } else {
                letterView.snp.makeConstraints { make in
                    make.leading.equalTo(letterViews[index - 1].snp.trailing)
                    make.top.bottom.equalToSuperview()
                }
            }
            
            if index == targetChars.count - 1 {
                letterView.snp.makeConstraints { make in
                    make.trailing.equalToSuperview()
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 处理输入字符
    /// - Parameter char: 输入的字符
    /// - Returns: 是否正确
    func handleInput(_ char: Character) -> Bool {
        let isCorrect = engine.input(char: char)
        
        if !isCorrect {
            // 输入错误：播放抖动动画
            playShakeAnimation()
            
            // 延迟 0.3 秒后清空并重新开始
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.engine.restart()
                self?.updateDisplay()
            }
        }
        
        updateDisplay()
        return isCorrect
    }
    
    /// 重置为新单词
    func reset(word: String) {
        engine.reset(newWord: word)
        createLetterViews()
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
        let settings = LLSettingsStore.shared.settings
        let isDictationMode = settings.typingDictationMode
        
        for (index, letterView) in letterViews.enumerated() {
            if index < engine.cursorIndex {
                // 已输入的字符（总是显示）
                letterView.setState(.typed, showText: true)
            } else if index == engine.cursorIndex {
                // 当前字符
                if engine.lastInputWasError {
                    letterView.setState(.error, showText: !isDictationMode)
                } else {
                    letterView.setState(.current, showText: !isDictationMode)
                }
            } else {
                // 未输入的字符（听写模式下隐藏）
                letterView.setState(.pending, showText: !isDictationMode)
            }
        }
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

// MARK: - LetterView

/// 单个字母视图（包含字母和下划线）
private class LetterView: NSView {
    
    private let label = NSTextField()
    private let underlineView = NSView()
    private let char: Character
    private let spacing: CGFloat
    
    init(char: Character, spacing: CGFloat) {
        self.char = char
        self.spacing = spacing
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        wantsLayer = true
        
        // 配置标签
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.alignment = .center
        label.font = NSFont.monospacedSystemFont(ofSize: 48, weight: .regular)
        label.stringValue = String(char)
        
        // 配置下划线
        underlineView.wantsLayer = true
        underlineView.layer?.backgroundColor = NSColor.systemBlue.cgColor
        
        addSubview(label)
        addSubview(underlineView)
        
        // 布局
        label.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(32)
            make.height.equalTo(60)
        }
        
        underlineView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.width.equalTo(32)
            make.height.equalTo(3)
            make.bottom.equalToSuperview()
        }
        
        // 添加右侧间距
        if spacing > 0 {
            self.snp.makeConstraints { make in
                make.width.equalTo(32 + spacing)
            }
        } else {
            self.snp.makeConstraints { make in
                make.width.equalTo(32)
            }
        }
    }
    
    enum State {
        case pending   // 未输入
        case current   // 当前
        case typed     // 已输入
        case error     // 错误
    }
    
    func setState(_ state: State, showText: Bool) {
        // 先清除背景色
        label.layer?.backgroundColor = NSColor.clear.cgColor
        
        // 设置文字显示/隐藏
        if showText {
            label.stringValue = String(char)
        } else {
            label.stringValue = ""
        }
        
        // 设置颜色
        switch state {
        case .pending:
            label.textColor = NSColor.gray.withAlphaComponent(0.3)
            underlineView.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.3).cgColor
            
        case .current:
            label.textColor = NSColor.gray.withAlphaComponent(0.3)
            underlineView.layer?.backgroundColor = NSColor.systemBlue.cgColor
            
        case .typed:
            label.textColor = NSColor.systemGreen
            underlineView.layer?.backgroundColor = NSColor.systemGreen.cgColor
            
        case .error:
            label.textColor = NSColor.white
            label.layer?.backgroundColor = NSColor.systemRed.cgColor
            underlineView.layer?.backgroundColor = NSColor.systemRed.cgColor
        }
    }
}

