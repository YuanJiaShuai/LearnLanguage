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
    
    private var currentEntry: LLWordEntry?
    private var currentListId: String?
    private var completedCount = 0
    private var currentWordErrorCount = 0 {
        didSet {
            displayView.answerAfterErrorCount(errorCount: currentWordErrorCount)
        }
    }  // 当前单词的累计错误次数
    private var hasRecordedFeedback = false  // 标记当前单词是否已记录反馈
    
    // MARK: - Callbacks
    
    var onWordCompleted: ((LLWordFeedback) -> Void)?
    
    // MARK: - Lifecycle
    
    override func loadView() {
        let settings = LLSettingsStore.shared.settings
        let width = settings.floatingPanelWidth
        let height = settings.floatingPanelHeight
        view = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
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
        
        // 从设置读取字体和字号
        let fontSize: CGFloat = settings.floatingPanelFontSize
        
        // 单词显示视图
        displayView = LLTypingDisplayView(word: "", fontSize: fontSize, fontName: settings.floatingPanelFontName)
        
        // 释义标签
        meaningLabel.isBezeled = false
        meaningLabel.drawsBackground = false
        meaningLabel.isEditable = false
        meaningLabel.isSelectable = false
        meaningLabel.alignment = .center
        meaningLabel.font = NSFont.systemFont(ofSize: 16)
        meaningLabel.textColor = .secondaryLabelColor
        meaningLabel.lineBreakMode = .byWordWrapping
        meaningLabel.maximumNumberOfLines = 3
        meaningLabel.cell?.wraps = true
        meaningLabel.cell?.isScrollable = false
        meaningLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // StackView 作为父视图，垂直排列，整体居中
        let stackView = NSStackView(views: [displayView, meaningLabel])
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.spacing = 16
        stackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.addSubview(stackView)
        
        let horizontalPadding: CGFloat = 12
        let displayHeight: CGFloat = 80.0
        
        displayView.snp.makeConstraints { make in
            make.height.equalTo(displayHeight)
            make.width.equalTo(stackView)
        }
        
        meaningLabel.snp.makeConstraints { make in
            make.width.equalTo(stackView)
        }
        
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.equalToSuperview().offset(horizontalPadding)
            make.right.equalToSuperview().offset(-horizontalPadding)
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
        }
    }
    
    // MARK: - Private Methods
    
    private func handleWordCompleted() {
        // 播放完成音效
        LLTypingSoundManager.shared.playCompleteSound()
        
        // 如果一次性输入正确（没有错误），记录为"认识"
        if currentWordErrorCount == 0 && !hasRecordedFeedback {
            recordFeedbackToDatabase(.know)
            hasRecordedFeedback = true
        } else if currentWordErrorCount == 1 && !hasRecordedFeedback {
            recordFeedbackToDatabase(.unclear)
            hasRecordedFeedback = true
        } else if currentWordErrorCount >= 2 && !hasRecordedFeedback {
            recordFeedbackToDatabase(.unknown)
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
        guard let entry = currentEntry else {
            LLLogger.warn("⚠️ 没有当前单词，无法记录反馈")
            return
        }
        
        // 通过每日学习管理器记录反馈
        LLDailyLearningManager.shared.recordFeedback(feedback, for: entry)
        
        LLLogger.info("✅ 已记录反馈: \(feedback) - \(entry.text)")
    }
}
