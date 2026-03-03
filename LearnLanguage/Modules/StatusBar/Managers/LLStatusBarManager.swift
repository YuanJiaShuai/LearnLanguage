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
    
    /// 右键菜单项提供者
    var menuProvider: (() -> NSMenu)?
    
    // MARK: - Initialization
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshStatusBar),
            name: .learnLanguageRefreshStatus,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSettingsChanged),
            name: .learnLanguageRefreshStatus,
            object: nil
        )
    }
    
    @objc private func onSettingsChanged() {
        // 当设置改变时，重新加载状态栏以应用新的宽度和按钮显示设置
        reloadStatusBar()
    }
    
    deinit {
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
        
        LLLogger.info("✅ 状态栏初始化完成")
    }
    
    /// 重新加载状态栏（用于设置改变后）
    func reloadStatusBar() {
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
        
        // 获取下一个单词（打字练习模式不影响状态栏显示）
        guard let listId = LLSettingsStore.shared.currentListId,
              let list = LLWordListStorage.shared.list(byId: listId),
              let next = LLLearningStore.shared.nextWord(in: list) else {
            LLLogger.warn("⚠️ 没有找到当前词库或下一个单词，显示默认文本")
            contentView?.updateContent(word: "LearnLanguage", phonetic: "", meaning: "")
            currentEntry = nil
            currentListId = nil
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
    }
    
    /// 记录反馈
    func recordFeedback(_ feedback: LLWordFeedback) {
        guard let entry = currentEntry, let listId = currentListId else {
            LLLogger.warn("⚠️ 没有当前单词，无法记录反馈")
            return
        }
        
        // 保存反馈
        LLLearningStore.shared.recordFeedback(
            wordId: entry.id,
            listId: listId,
            feedback: feedback
        )
        
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
    
    /// 切换打字练习模式
    func toggleTypingPracticeMode() {
        isTypingPracticeMode.toggle()
    }
    
    // MARK: - Private Methods
    
    private func setupMainStatusItem(in bar: NSStatusBar) {
        let settings = LLSettingsStore.shared.settings
        let length = settings.statusBarShowContent ? CGFloat(settings.statusBarContentWidth) : NSStatusItem.variableLength
        
        statusItem = bar.statusItem(withLength: length)
        
        // 创建自定义视图
        let menu = menuProvider?()
        contentView = LLStatusBarContentView(statusItem: statusItem!, menu: menu)
        
        // 设置视图的 target 和 action
        contentView?.target = self
        contentView?.action = #selector(statusItemClicked(_:))
        
        // 将自定义视图添加到 button 中
        if let button = statusItem?.button {
            button.title = ""
            button.image = nil
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

