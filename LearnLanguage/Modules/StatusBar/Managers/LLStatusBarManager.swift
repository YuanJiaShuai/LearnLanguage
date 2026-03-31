//
//  LLStatusBarManager.swift
//  LearnLanguage
//
//  状态栏管理器 - 负责状态栏的显示和交互
//

import AppKit
import Cocoa
import SnapKit
import SnapKit

final class LLStatusBarManager {
    
    static let shared = LLStatusBarManager()
    
    // MARK: - Properties
    
    /// 主状态项（显示单词）
    private var statusItem: NSStatusItem?
    
    /// 自定义状态栏内容视图
    private var contentView: LLStatusBarContentView?
    
    /// 反馈按钮状态项（三个图标）
    private var feedbackStatusItem: NSStatusItem?
    
    /// 当前正在展示的词条
    private var currentEntry: LLWordEntry?
    
    /// 当前词库 ID
    private var currentListId: String?
    
    /// 播放定时器
    private var playbackTimer: Timer?
    
    /// 是否处于打字练习模式
    var isTypingPracticeMode = false {
        didSet {
            refreshStatusBar()
            NotificationCenter.default.post(
                name: .statusBarTypingPracticeModeChanged,
                object: isTypingPracticeMode
            )
        }
    }
    
    /// 点击状态栏的回调
    var onStatusBarClicked: (() -> Void)?
    
    // MARK: - Initialization
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // 监听设置改变（重新加载状态栏）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSettingsChanged),
            name: .learnLanguageRefreshStatus,
            object: nil
        )
        
        // 监听当前词库切换（刷新状态栏显示的单词）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onCurrentWordListChanged),
            name: .currentWordListChanged,
            object: nil
        )
    }
    
    @objc private func onSettingsChanged() {
        // 当状态栏设置改变时，重新加载状态栏
        // 注意：浮窗设置变化（.floatingPanelSettingsChanged）不会触发此方法
        reloadStatusBar()
    }
    
    @objc private func onCurrentWordListChanged() {
        // 当前词库切换时，刷新状态栏显示新词库的单词
        refreshStatusBar()
    }
    
    deinit {
        stopPlaybackTimer()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// 初始化状态栏
    func setupStatusBar() {
        let bar = NSStatusBar.system
        
        // 创建主状态项（显示单词，反馈按钮已整合在内部）
        setupMainStatusItem(in: bar)
        
        // 刷新显示
        refreshStatusBar()
        
        // 启动播放定时器
        startPlaybackTimer()
        
        LLLogger.info("✅ 状态栏初始化完成")
    }
    
    /// 重新加载状态栏（用于设置改变后）
    func reloadStatusBar() {
        // 停止旧定时器
        stopPlaybackTimer()
        
        // 移除旧的状态栏项
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
        
        // 重新初始化
        setupStatusBar()
        
        LLLogger.info("✅ 状态栏已重新加载")
    }
    
    /// 刷新状态栏显示
    @objc func refreshStatusBar() {
        LLLogger.debug("🔄 刷新状态栏...")
        
        let settings = LLSettingsStore.shared.settings
        
        // 如果设置了不显示内容
        if !settings.statusBarShowContent {
            contentView?.updateContent(word: "", phonetic: "", meaning: "")
            LLLogger.info("✅ 状态栏隐藏内容")
            return
        }
        
        // 初始化今日学习队列
        guard let listId = LLSettingsStore.shared.currentListId else {
            LLLogger.warn("⚠️ 没有找到当前词库，显示默认文本")
            contentView?.updateContent(word: "LearnLanguage", phonetic: "", meaning: "")
            currentEntry = nil
            currentListId = nil
            return
        }
        
        LLDailyLearningManager.shared.setup(listId: listId)
        
        // 从每日学习管理器获取下一个词（复习优先）
        guard let next = LLDailyLearningManager.shared.nextWord() else {
            LLLogger.warn("⚠️ 今日学习任务已完成或词库为空")
            contentView?.updateContent(word: "今日完成 🎉", phonetic: "", meaning: "")
            currentEntry = nil
            currentListId = listId
            return
        }
        
        // 更新当前单词
        currentEntry = next
        currentListId = listId
        
        // 获取单词、音标、释义
        let word = next.text
        let phonetic = next.phonetic ?? ""
        let meaning = next.meaning
        
        contentView?.updateContent(word: word, phonetic: phonetic, meaning: meaning)
        LLLogger.debug("✅ 状态栏显示: \(word) \(phonetic) - \(meaning)")
        
        // 根据发音设置播放单词发音
        let interval = settings.statusBarPlaybackInterval
        if settings.pronunciationEnabled && interval >= 0 {
            LLPronunciationManager.shared.speak(word: word)
        }
    }
    
    /// 记录反馈
    func recordFeedback(_ feedback: LLWordFeedback) {
        guard let entry = currentEntry, let listId = currentListId else {
            LLLogger.warn("⚠️ 没有当前单词，无法记录反馈")
            return
        }
        
        // 通过每日学习管理器记录反馈（更新数据库 + 更新内存队列）
        LLDailyLearningManager.shared.recordFeedback(feedback, for: entry)
        
        // 发送通知
        NotificationCenter.default.post(
            name: .statusBarFeedbackSelected,
            object: feedback
        )
        
        LLLogger.info("✅ 已记录反馈: \(feedback)")
        
        // 刷新显示下一个单词
        refreshStatusBar()
    }
    
    /// 获取当前单词
    func getCurrentWord() -> LLWordEntry? {
        return currentEntry
    }
    
    /// 切换到下一个单词
    func moveToNextWord() {
        refreshStatusBar()
    }
    
    /// 播放当前单词发音
    func playCurrentWordPronunciation() {
        guard let entry = currentEntry else { return }
        LLPronunciationManager.shared.speak(word: entry.text)
    }
    
    /// 切换打字练习模式
    func toggleTypingPracticeMode() {
        isTypingPracticeMode.toggle()
    }
    
    // MARK: - Playback Timer
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        
        let settings = LLSettingsStore.shared.settings
        let interval = settings.statusBarPlaybackInterval
        
        // 只播放1次（interval == 0）：不启动定时器
        guard interval > 0 else {
            LLLogger.info("⏱ 播放设置：只播放1次，不启动定时器")
            return
        }
        
        LLLogger.info("⏱ 启动播放定时器，间隔：\(interval)秒")
        
        playbackTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(interval),
            repeats: true
        ) { [weak self] _ in
            LLLogger.debug("⏱ 定时器触发，切换下一个单词")
            self?.refreshStatusBar()
        }
        
        // 加入 RunLoop 确保在滚动等场景下也能触发
        if let timer = playbackTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
        LLLogger.info("⏱ 播放定时器已停止")
    }
    
    // MARK: - Private Methods
    
    private func setupMainStatusItem(in bar: NSStatusBar) {
        let settings = LLSettingsStore.shared.settings
        let configuredLength = settings.statusBarShowContent ? CGFloat(settings.statusBarContentWidth) : NSStatusItem.variableLength
        let minimumLength = LLStatusBarContentView.minimumRequiredWidth()
        let length: CGFloat = {
            guard configuredLength != NSStatusItem.variableLength else { return configuredLength }
            return max(configuredLength, minimumLength)
        }()
        
        statusItem = bar.statusItem(withLength: length)
        
        // 创建自定义视图（不再需要 NSMenu）
        contentView = LLStatusBarContentView(statusItem: statusItem!)
        
        // 将自定义视图添加到 button 中
        if let button = statusItem?.button {
            button.title = ""
            button.image = nil
            button.action = nil  // 清除 button 的 action，让事件传递给 contentView
            button.target = nil
            button.subviews.forEach { $0.removeFromSuperview() }
            button.addSubview(contentView!)
            
            // 使用 SnapKit 让视图填满整个 button
            contentView?.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        LLLogger.debug("✅ 主状态栏项已创建，宽度: \(length)")
    }
    
    @objc private func statusItemClicked(_ sender: Any) {
        // 触发回调
        onStatusBarClicked?()
    }
}

