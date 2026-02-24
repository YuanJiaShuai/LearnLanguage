//
//  LLTypingPracticeViewController.swift
//  LearnLanguage
//
//  打字练习视图控制器 - 重构版

import AppKit
import SnapKit

class LLTypingPracticeViewController: NSViewController {
    
    // MARK: - Properties
    
    private var displayView: LLTypingDisplayView!
    private let meaningLabel = NSTextField()
    private let statsLabel = NSTextField()
    private let hintLabel = NSTextField()
    
    private var currentEntry: LLWordEntry?
    
    // MARK: - Callbacks
    
    var onNextWord: (() -> Void)?
    var onWordCompleted: ((LLWordFeedback) -> Void)?
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        view.wantsLayer = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(view)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // 单词显示视图
        displayView = LLTypingDisplayView(word: "")
        view.addSubview(displayView)
        
        // 释义标签
        meaningLabel.isBezeled = false
        meaningLabel.drawsBackground = false
        meaningLabel.isEditable = false
        meaningLabel.isSelectable = false
        meaningLabel.alignment = .center
        meaningLabel.font = NSFont.systemFont(ofSize: 16)
        meaningLabel.textColor = .secondaryLabelColor
        meaningLabel.lineBreakMode = .byWordWrapping
        meaningLabel.maximumNumberOfLines = 2
        view.addSubview(meaningLabel)
        
        // 统计标签
        statsLabel.isBezeled = false
        statsLabel.drawsBackground = false
        statsLabel.isEditable = false
        statsLabel.isSelectable = false
        statsLabel.alignment = .center
        statsLabel.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        statsLabel.textColor = .tertiaryLabelColor
        view.addSubview(statsLabel)
        
        // 提示标签
        hintLabel.isBezeled = false
        hintLabel.drawsBackground = false
        hintLabel.isEditable = false
        hintLabel.isSelectable = false
        hintLabel.alignment = .center
        hintLabel.font = NSFont.systemFont(ofSize: 12)
        hintLabel.textColor = .tertiaryLabelColor
        hintLabel.stringValue = "开始输入单词..."
        view.addSubview(hintLabel)
        
        // 布局
        displayView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-30)
            make.left.right.equalToSuperview()
            make.height.equalTo(80)
        }
        
        meaningLabel.snp.makeConstraints { make in
            make.top.equalTo(displayView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
        }
        
        statsLabel.snp.makeConstraints { make in
            make.top.equalTo(meaningLabel.snp.bottom).offset(15)
            make.centerX.equalToSuperview()
        }
        
        hintLabel.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    
    /// 开始练习
    func startPractice(with entry: LLWordEntry) {
        currentEntry = entry
        displayView.reset(word: entry.text)
        
        // 设置释义
        let settings = LLSettingsStore.shared.settings
        meaningLabel.stringValue = settings.typingPracticeShowMeaning ? entry.meaning : ""
        
        // 重置统计
        updateStats()
        hintLabel.stringValue = "开始输入单词..."
        
        // 播放发音
        if settings.pronunciationEnabled {
            LLPronunciationManager.shared.speak(word: entry.text)
        }
        
        // 确保窗口获得焦点
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.view.window?.makeFirstResponder(self?.view)
        }
    }
    
    // MARK: - Keyboard Handling
    
    override func keyDown(with event: NSEvent) {
        // 处理特殊键
        switch event.keyCode {
        case 36: // Enter - 跳过当前单词
            onNextWord?()
            return
        default:
            break
        }
        
        // 处理字符输入
        guard let chars = event.characters, chars.count == 1 else {
            super.keyDown(with: event)
            return
        }
        
        let char = chars.first!
        
        // 忽略控制字符
        guard !char.isWhitespace && !char.isNewline else {
            super.keyDown(with: event)
            return
        }
        
        // 处理输入
        let isCorrect = displayView.handleInput(char)
        
        if isCorrect {
            // 正确输入
            LLTypingSoundManager.shared.playKeySound()
            hintLabel.stringValue = "✓ 正确"
            hintLabel.textColor = .systemGreen
            
            // 更新统计
            updateStats()
            
            // 检查是否完成
            if displayView.isFinished {
                handleWordCompleted()
            }
        } else {
            // 错误输入
            LLTypingSoundManager.shared.playWrongSound()
            hintLabel.stringValue = "✗ 输入错误"
            hintLabel.textColor = .systemRed
            
            // 更新统计
            updateStats()
        }
    }
    
    // MARK: - Private Methods
    
    private func handleWordCompleted() {
        // 播放完成音效
        LLTypingSoundManager.shared.playCompleteSound()
        
        // 根据错误次数判断反馈
        let feedback: LLWordFeedback
        let errors = displayView.errorCount
        
        if errors == 0 {
            feedback = .know
            hintLabel.stringValue = "🎉 完美！"
            hintLabel.textColor = .systemGreen
        } else if errors <= 2 {
            feedback = .unclear
            hintLabel.stringValue = "✓ 完成（\(errors) 个错误）"
            hintLabel.textColor = .systemOrange
        } else {
            feedback = .unknown
            hintLabel.stringValue = "✓ 完成（\(errors) 个错误）"
            hintLabel.textColor = .systemRed
        }
        
        // 延迟 0.4s 后切换下一个单词
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.onWordCompleted?(feedback)
        }
    }
    
    private func updateStats() {
        let accuracy = displayView.accuracy
        let speed = displayView.speed
        let errors = displayView.errorCount
        
        statsLabel.stringValue = String(format: "准确率: %d%% | 速度: %d 字符/分 | 错误: %d", 
                                        accuracy, speed, errors)
    }
}
