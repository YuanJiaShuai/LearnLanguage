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
    private var hasRecordedFeedback = false  // 标记当前单词是否已记录反馈
    
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
        // 获取浮窗尺寸
        let settings = LLSettingsStore.shared.settings
        let panelWidth = settings.floatingPanelWidth
        let panelHeight = settings.floatingPanelHeight
        
        // 基准尺寸（用于等比缩放）
        let baseWidth: CGFloat = 500.0
        let baseHeight: CGFloat = 350.0
        
        // 计算缩放比例（取宽高中较小的比例，保持协调）
        let scaleX = panelWidth / baseWidth
        let scaleY = panelHeight / baseHeight
        let scale = min(scaleX, scaleY)
        
        // 根据缩放比例计算字体大小（基准：48）
        let baseFontSize: CGFloat = 48.0
        let fontSize = max(20, baseFontSize * scale)
        
        // 单词显示视图
        displayView = LLTypingDisplayView(word: "", fontSize: fontSize)
        view.addSubview(displayView)
        
        // 释义标签
        meaningLabel.isBezeled = false
        meaningLabel.drawsBackground = false
        meaningLabel.isEditable = false
        meaningLabel.isSelectable = false
        meaningLabel.alignment = .center
        meaningLabel.font = NSFont.systemFont(ofSize: max(12, fontSize * 0.33))
        meaningLabel.textColor = .secondaryLabelColor
        meaningLabel.lineBreakMode = .byWordWrapping
        meaningLabel.maximumNumberOfLines = 3
        meaningLabel.cell?.wraps = true
        meaningLabel.cell?.isScrollable = false
        view.addSubview(meaningLabel)
        
        // 布局（所有间距和尺寸都等比缩放）
        let baseDisplayHeight: CGFloat = 80.0
        let displayHeight = max(60, baseDisplayHeight * scale)
        
        let baseVerticalOffset: CGFloat = -20.0
        let verticalOffset = baseVerticalOffset * scale
        
        let baseSpacing: CGFloat = 20.0
        let spacing = baseSpacing * scale
        
        let baseHorizontalPadding: CGFloat = 30.0
        let horizontalPadding = baseHorizontalPadding * scale
        
        displayView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(verticalOffset)
            make.left.right.equalToSuperview()
            make.height.equalTo(displayHeight)
        }
        
        let meaningFontSize = max(12, fontSize * 0.33)
        let meaningLineHeight = meaningFontSize * 1.4
        let meaningMaxHeight = meaningLineHeight * 3 + 4
        
        meaningLabel.snp.makeConstraints { make in
            make.top.equalTo(displayView.snp.bottom).offset(spacing)
            make.centerX.equalToSuperview()
            make.left.equalToSuperview().offset(horizontalPadding)
            make.right.equalToSuperview().offset(-horizontalPadding)
            make.height.lessThanOrEqualTo(meaningMaxHeight)
        }
    }
    
    // MARK: - Public Methods
    
    /// 开始练习
    func startPractice(with entry: LLWordEntry, listId: String? = nil) {
        currentEntry = entry
        currentListId = listId
        currentWordErrorCount = 0  // 重置错误计数
        hasRecordedFeedback = false  // 重置反馈记录标记
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
            
            // 只要输错一次，立即记录为"不认识"（只记录一次）
            if !hasRecordedFeedback {
                recordFeedbackToDatabase(.unknown)
                hasRecordedFeedback = true
            }
            
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
                LLLogger.info("✅ 已添加到错题本：\(entry.text)（错误\(currentWordErrorCount)次）")
            } catch {
                LLLogger.error("❌ 添加到错题本失败：\(error)")
            }
        }
    }
    
    private func handleWordCompleted() {
        guard let entry = currentEntry else { return }
        
        // 播放完成音效
        LLTypingSoundManager.shared.playCompleteSound()
        
        // 如果一次性输入正确（没有错误），记录为"认识"
        if currentWordErrorCount == 0 && !hasRecordedFeedback {
            recordFeedbackToDatabase(.know)
            hasRecordedFeedback = true
        }
        
        completedCount += 1
        
        // 延迟 0.4s 后切换下一个单词
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            // 传递 feedback 用于其他逻辑（如音效、动画等）
            let feedback: LLWordFeedback = (self?.currentWordErrorCount == 0) ? .know : .unknown
            self?.onWordCompleted?(feedback)
        }
    }
    
    private func skipCurrentWord() {
        // 跳过当前单词，标记为不认识
        if !hasRecordedFeedback {
            recordFeedbackToDatabase(.unknown)
            hasRecordedFeedback = true
        }
        onWordCompleted?(.unknown)
    }
    
    /// 记录反馈到数据库（只记录一次）
    private func recordFeedbackToDatabase(_ feedback: LLWordFeedback) {
        guard let entry = currentEntry, let listId = currentListId else {
            LLLogger.warn("⚠️ 没有当前单词，无法记录反馈")
            return
        }
        
        // 保存反馈到 JSON（兼容旧逻辑）
        LLLearningStore.shared.recordFeedback(
            wordId: entry.id,
            listId: listId,
            feedback: feedback
        )
        
        // 保存反馈到 WCDB（主要存储）
        do {
            try LLDatabaseManager.shared.recordLearningProgress(
                wordId: entry.id,
                wordListId: listId,
                feedback: feedback.rawValue
            )
            LLLogger.info("✅ 已记录反馈: \(feedback) - \(entry.text)")
        } catch {
            LLLogger.error("❌ WCDB 记录学习进度失败：\(error)")
        }
        
        // 发送通知
        NotificationCenter.default.post(
            name: .statusBarFeedbackSelected,
            object: feedback
        )
    }
}
