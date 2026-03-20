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
    public var currentWordErrorCount: Int = 0
    
    /// 字体大小（影响字母大小、下划线宽度/高度等比缩放）
    var fontSize: CGFloat = 48 {
        didSet {
            if oldValue != fontSize {
                createLetterViews()
                updateDisplay()
            }
        }
    }
    
    // MARK: - Initialization
    
    init(word: String, fontSize: CGFloat = 48) {
        self.engine = LLTypingEngine(targetWord: word)
        self.fontSize = fontSize
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
        
        // 根据字体大小等比计算字母宽度和间距
        let letterWidth = (fontSize / 48.0) * 32
        let letterSpacing = inputStyle == .perLetter ? (fontSize / 48.0) * 8 : 0
        
        for (index, char) in targetChars.enumerated() {
            let letterView = LetterView(
                char: char,
                fontSize: fontSize,
                letterWidth: letterWidth,
                spacing: letterSpacing
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
    func handleInput(_ char: Character) -> Bool {
        let isCorrect = engine.input(char: char)
        
        if !isCorrect {
            playShakeAnimation()
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
    
    func answerAfterErrorCount(errorCount: Int) {
        let settings = LLSettingsStore.shared.settings
        currentWordErrorCount = errorCount
        if currentWordErrorCount >= settings.autoShowAnswerAfterErrors {
            updateDisplay()
        }
    }
    
    var isFinished: Bool { engine.isFinished }
    var errorCount: Int { engine.errorCount }
    var accuracy: Int { engine.accuracy }
    var speed: Int { engine.speed }
    var elapsedTime: TimeInterval { engine.elapsedTime }
    
    // MARK: - Private Methods
    
    private func updateDisplay() {
        let settings = LLSettingsStore.shared.settings
        let isDictationMode = !settings.typingDictationMode || currentWordErrorCount >= settings.autoShowAnswerAfterErrors
        
        for (index, letterView) in letterViews.enumerated() {
            if index < engine.cursorIndex {
                letterView.setState(.typed, showText: true)
            } else if index == engine.cursorIndex {
                if engine.lastInputWasError {
                    letterView.setState(.error, showText: isDictationMode)
                } else {
                    letterView.setState(.current, showText: isDictationMode)
                }
            } else {
                letterView.setState(.pending, showText: isDictationMode)
            }
        }
    }
    
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

private class LetterView: NSView {
    
    private let label = NSTextField()
    private let underlineView = NSView()
    private let char: Character
    private let fontSize: CGFloat
    private let letterWidth: CGFloat
    private let spacing: CGFloat
    
    init(char: Character, fontSize: CGFloat, letterWidth: CGFloat, spacing: CGFloat) {
        self.char = char
        self.fontSize = fontSize
        self.letterWidth = letterWidth
        self.spacing = spacing
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        wantsLayer = true
        
        // 下划线高度和字母高度等比缩放
        let underlineHeight = max(2, (fontSize / 48.0) * 3)
        let labelHeight = (fontSize / 48.0) * 60
        
        label.isBezeled = false
        label.drawsBackground = false
        label.isEditable = false
        label.isSelectable = false
        label.alignment = .center
        label.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        label.stringValue = String(char)
        
        underlineView.wantsLayer = true
        underlineView.layer?.backgroundColor = NSColor.systemBlue.cgColor
        
        addSubview(label)
        addSubview(underlineView)
        
        label.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(letterWidth)
            make.height.equalTo(labelHeight)
        }
        
        underlineView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.width.equalTo(letterWidth)
            make.height.equalTo(underlineHeight)
            make.bottom.equalToSuperview()
        }
        
        let totalWidth = letterWidth + spacing
        self.snp.makeConstraints { make in
            make.width.equalTo(totalWidth)
        }
    }
    
    enum State {
        case pending, current, typed, error
    }
    
    func setState(_ state: State, showText: Bool) {
        label.layer?.backgroundColor = NSColor.clear.cgColor
        label.stringValue = showText ? String(char) : ""
        
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
