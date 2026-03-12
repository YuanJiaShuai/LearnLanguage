//
//  NotificationName+Extensions.swift
//  LearnLanguage
//
//  统一管理所有通知名称
//

import Foundation

extension Notification.Name {
    
    // MARK: - 词库管理相关
    
    /// 刷新状态通知
    static let learnLanguageRefreshStatus = Notification.Name("LearnLanguage.refreshStatus")
    
    /// 重新加载词库列表通知
    static let learnLanguageReloadWordLists = Notification.Name("LearnLanguage.reloadWordLists")
    
    /// 当前词库改变通知
    static let learnLanguageCurrentListChanged = Notification.Name("LearnLanguage.currentListChanged")
    
    /// 当前学习词库改变通知（侧边栏使用）
    static let currentWordListChanged = Notification.Name("currentWordListChanged")
    
    /// 错题数量改变通知
    static let wrongWordsCountChanged = Notification.Name("wrongWordsCountChanged")
    
    // MARK: - 状态栏相关
    
    /// 状态栏反馈选择通知
    static let statusBarFeedbackSelected = Notification.Name("LLStatusBarFeedbackSelected")
    
    /// 打字练习模式改变通知
    static let statusBarTypingPracticeModeChanged = Notification.Name("LLStatusBarTypingPracticeModeChanged")
    
    /// 浮窗设置改变通知
    static let floatingPanelSettingsChanged = Notification.Name("LLFloatingPanelSettingsChanged")
}

