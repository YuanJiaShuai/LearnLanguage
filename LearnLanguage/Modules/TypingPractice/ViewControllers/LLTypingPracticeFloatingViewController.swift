//
//  LLTypingPracticeFloatingViewController.swift
//  LearnLanguage
//
//  浮动窗口打字练习控制器 - 重构版
//  使用新的 LLTypingEngine 和 LLTypingDisplayView
//

import AppKit
import SnapKit

class LLTypingPracticeFloatingViewController: NSViewController {
    
    // MARK: - Properties
    
    private var displayView: LLTypingDisplayView!
    private let meaningLabel = NSTextField()
    // private let statsLabel = NSTextField()  // 移除统计
    // private let hintLabel = NSTextField()   // 移除提示
    
    private var currentEntry: LLWordEntry?
    private var currentListId: String?
    private var completedCount = 0
    private var currentWordErrorCount = 0  // 当前单词的累计错误次数
    
    // MARK: - Callbacks
    
    var onWordCompleted: ((LLWordFeedback) -> Void)?
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 500, height: 350))
        view.wantsLayer = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // 确保窗口可以接收键盘事件
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
        
        // 布局
        displayView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-20)
            make.left.right.equalToSuperview()
            make.height.equalTo(80)
        }
        
        meaningLabel.snp.makeConstraints { make in
            make.top.equalTo(displayView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(30)
            make.right.equalToSuperview().offset(-30)
        }
    }
    
    // MARK: - Public Methods
    
    /// 开始练习
    func startPractice(with entry: LLWordEntry, listId: String? = nil) {
        currentEntry = entry
        currentListId = listId
        currentWordErrorCount = 0  // 重置错误计数
        displayView.reset(word: entry.text)
        
        // 设置释义
        let settings = LLSettingsStore.shared.settings
        meaningLabel.stringValue = settings.typingPracticeShowMeaning ? entry.meaning : ""
        
        // 播放发音
        if settings.pronunciationEnabled {
            LLPronunciationManager.shared.speak(word: entry.text)
        }
        
        // 确保窗口获得焦点
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.view.window?.makeFirstResponder(self?.view)
        }
    }
    
    /// 重置视图
    func resetView() {
        meaningLabel.stringValue = "点击切换到练习"
    }
    
    // 保留这个属性用于外部访问（兼容性）
    let targetWordLabel = NSTextField()
    
    // MARK: - Keyboard Handling
    
    override func keyDown(with event: NSEvent) {
        // 处理特殊键
        switch event.keyCode {
        case 53: // ESC - 隐藏窗口
            view.window?.orderOut(nil)
            return
        case 36: // Enter - 跳过当前单词
            skipCurrentWord()
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
            
            // 检查是否完成
            if displayView.isFinished {
                handleWordCompleted()
            }
        } else {
            // 错误输入
            LLTypingSoundManager.shared.playWrongSound()
            
            // 累计错误次数
            currentWordErrorCount += 1
            
            // 检查是否需要添加到错题本
            checkAndAddToWrongBook()
        }
    }
    
    // MARK: - Private Methods
    
    /// 检查并添加到错题本
    private func checkAndAddToWrongBook() {
        guard let entry = currentEntry,
              let listId = currentListId else {
            return
        }
        
        let settings = LLSettingsStore.shared.settings
        let threshold = settings.addToWrongBookAfterErrors
        
        // 如果设置为"不记录"，直接返回
        if threshold == 999 {
            return
        }
        
        // 如果错误次数达到阈值，添加到错题本
        if currentWordErrorCount >= threshold {
            do {
                try LLDatabaseManager.shared.addOrUpdateWrongRecord(
                    wordId: entry.id,
                    listId: listId,
                    word: entry.text,
                    meaning: entry.meaning
                )
                print("✅ 已添加到错题本：\(entry.text)（错误\(currentWordErrorCount)次）")
            } catch {
                print("❌ 添加到错题本失败：\(error)")
            }
        }
    }
    
    private func handleWordCompleted() {
        guard let entry = currentEntry else { return }
        
        // 播放完成音效
        LLTypingSoundManager.shared.playCompleteSound()
        
        // 根据错误次数判断反馈
        let feedback: LLWordFeedback
        let errors = displayView.errorCount
        
        if errors == 0 {
            feedback = .know
        } else if errors <= 2 {
            feedback = .unclear
        } else {
            feedback = .unknown
        }
        
        completedCount += 1
        
        // 延迟 0.4s 后切换下一个单词
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.onWordCompleted?(feedback)
        }
    }
    
    private func skipCurrentWord() {
        // 跳过当前单词，标记为不认识
        onWordCompleted?(.unknown)
    }
}
