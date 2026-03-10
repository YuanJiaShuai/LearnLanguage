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
    
    private init() {}
    
    func startPractice(listId: String) {
        currentListId = listId
    }
    
    /// 获取下一个单词（与状态栏逻辑统一）
    func getNextWord() -> LLWordEntry? {
        guard let listId = currentListId,
              let wordList = LLWordListStorage.shared.list(byId: listId) else {
            return nil
        }
        
        // 使用 WCDB 获取下一个单词
        let nextEntry = LLDatabaseManager.shared.nextWord(in: wordList)
        currentEntry = nextEntry
        
        return nextEntry
    }
    
    /// 获取当前状态栏显示的单词（优先使用）
    func getCurrentStatusBarWord() -> LLWordEntry? {
        return LLStatusBarManager.shared.getCurrentWord()
    }
    
    func recordResult(feedback: LLWordFeedback) {
        guard let entry = currentEntry, let listId = currentListId else { return }
        
        // 记录到 WCDB 学习进度表
        do {
            try LLDatabaseManager.shared.recordLearningProgress(
                wordId: entry.id,
                wordListId: listId,
                feedback: feedback.rawValue
            )
            
            // 记录打字练习
            try LLDatabaseManager.shared.recordTypingPractice(
                wordId: entry.id,
                wordListId: listId
            )
            
            LLLogger.info("✅ 已记录学习进度：\(entry.text) - \(feedback.rawValue)")
        } catch {
            LLLogger.error("❌ 记录学习进度失败：\(error)")
        }
        
        // 同步刷新状态栏（显示下一个单词）
        LLStatusBarManager.shared.refreshStatusBar()
    }
    
    func hasNextWord() -> Bool {
        guard let listId = currentListId,
              let wordList = LLWordListStorage.shared.list(byId: listId) else {
            return false
        }
        
        return LLDatabaseManager.shared.nextWord(in: wordList) != nil
    }
    
    private func getCurrentList() -> WordList? {
        guard let listId = currentListId else { return nil }
        return LLWordListStorage.shared.list(byId: listId)
    }
}