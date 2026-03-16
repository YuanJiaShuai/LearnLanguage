//
//  LLLocalizationManager.swift
//  LearnLanguage
//
//  本地化管理器 - 管理应用显示语言

import Foundation
import AppKit

final class LLLocalizationManager {
    
    static let shared = LLLocalizationManager()
    
    // MARK: - Properties
    
    private var currentLanguage: LLDisplayLanguage {
        didSet {
            applyLanguage(currentLanguage)
        }
    }
    
    // MARK: - Init
    
    private init() {
        self.currentLanguage = LLSettingsStore.shared.settings.displayLanguage
        applyLanguage(currentLanguage)
    }
    
    // MARK: - Public Methods
    
    /// 获取当前显示语言
    func getCurrentLanguage() -> LLDisplayLanguage {
        return currentLanguage
    }
    
    /// 设置显示语言
    func setLanguage(_ language: LLDisplayLanguage) {
        guard language != currentLanguage else { return }
        
        currentLanguage = language
        
        // 保存到设置
        var settings = LLSettingsStore.shared.settings
        settings.displayLanguage = language
        LLSettingsStore.shared.settings = settings
        
        // 发送通知，让 UI 更新
        NotificationCenter.default.post(
            name: NSNotification.Name("LLDisplayLanguageChanged"),
            object: language
        )
        
        LLLogger.info("🌐 显示语言已切换为：\(language.displayName)")
    }
    
    // MARK: - Private Methods
    
    /// 应用语言设置
    private func applyLanguage(_ language: LLDisplayLanguage) {
        // 这里可以设置系统语言相关的配置
        // 目前主要是通过 Localizable.strings 文件实现
        // 后续可以在这里添加更多语言相关的初始化逻辑
    }
    
    // MARK: - Localization Helpers
    
    /// 获取本地化字符串
    /// 使用方式：LLLocalizationManager.shared.localized("key")
    func localized(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, comment: comment)
    }
}

// MARK: - Notification Extension

extension NSNotification.Name {
    static let displayLanguageChanged = NSNotification.Name("LLDisplayLanguageChanged")
}
