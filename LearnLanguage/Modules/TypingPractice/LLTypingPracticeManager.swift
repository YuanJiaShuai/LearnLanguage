//
//  LLTypingPracticeManager.swift
//  LearnLanguage
//
//  打字练习管理器 - 与状态栏逻辑统一，使用相同的学习进度
//

import Foundation

class LLTypingPracticeManager {
    static let shared = LLTypingPracticeManager()
    
    private var currentListId: String?
    private var currentEntry: LLWordEntry?
    
    /// 当前单词本次练习的错误次数
    private var currentErrorCount: Int = 0
    
    private init() {}
    
    func startPractice(listId: String) {
        currentListId = listId
        // 确保每日学习队列已初始化
        LLDailyLearningManager.shared.setup(listId: listId)
    }
    
    /// 获取下一个单词（与状态栏共享每日学习队列）
    func getNextWord() -> LLWordEntry? {
        let nextEntry = LLDailyLearningManager.shared.nextWord()
        currentEntry = nextEntry
        currentErrorCount = 0  // 重置错误计数
        return nextEntry
    }
    
    /// 获取当前状态栏显示的单词（优先使用）
    func getCurrentStatusBarWord() -> LLWordEntry? {
        return LLStatusBarManager.shared.getCurrentWord()
    }
    
    /// 记录打字错误（每次输入错误时调用）
    func recordTypingError() {
        currentErrorCount += 1
    }
    
    /// 记录打字完成结果（输入正确时调用）
    /// errorCount 由外部传入，或使用内部累计的 currentErrorCount
    func recordResult(errorCount: Int? = nil) {
        guard let entry = currentEntry else { return }
        
        let errors = errorCount ?? currentErrorCount
        
        // 通过每日学习管理器记录打字结果（自动映射 errorCount -> feedback）
        LLDailyLearningManager.shared.recordTypingResult(entry: entry, errorCount: errors)
        
        // 重置错误计数
        currentErrorCount = 0
        
        // 同步刷新状态栏
        LLStatusBarManager.shared.refreshStatusBar()
    }
    
    /// 兼容旧接口：直接传入 feedback
    func recordResult(feedback: LLWordFeedback) {
        guard let entry = currentEntry, let listId = currentListId else { return }
        
        LLDailyLearningManager.shared.recordFeedback(feedback, for: entry)
        
        LLLogger.info("✅ 已记录学习进度：\(entry.text) - \(feedback.rawValue)")
        
        // 同步刷新状态栏
        LLStatusBarManager.shared.refreshStatusBar()
    }
    
    func hasNextWord() -> Bool {
        return LLDailyLearningManager.shared.hasPendingTasks
    }
}