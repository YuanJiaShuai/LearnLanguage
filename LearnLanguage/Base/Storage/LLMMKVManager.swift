//
//  LLMMKVManager.swift
//  LearnLanguage
//
//  MMKV 配置管理器（用于存储轻量级配置和用户偏好）
//

import Foundation
import MMKV

/// MMKV 配置管理器
final class LLMMKVManager {
    
    static let shared = LLMMKVManager()
    
    private let mmkv: MMKV?
    
    private init() {
        // 初始化 MMKV
        MMKV.initialize(rootDir: nil)
        mmkv = MMKV.default()
        
        print("✅ MMKV 初始化成功")
        
        // 首次启动时从 UserDefaults 迁移数据
        migrateFromUserDefaultsIfNeeded()
    }
    
    // MARK: - 通用方法
    
    func set<T>(_ value: T, forKey key: String) {
        switch value {
        case let v as Bool:
            mmkv?.set(v, forKey: key)
        case let v as Int:
            mmkv?.set(Int32(v), forKey: key)
        case let v as Int64:
            mmkv?.set(v, forKey: key)
        case let v as Double:
            mmkv?.set(v, forKey: key)
        case let v as String:
            mmkv?.set(v, forKey: key)
        case let v as Data:
            mmkv?.set(v, forKey: key)
        default:
            print("⚠️ MMKV 不支持的类型：\(type(of: value))")
        }
    }
    
    func bool(forKey key: String, defaultValue: Bool = false) -> Bool {
        return mmkv?.bool(forKey: key) ?? defaultValue
    }
    
    func int(forKey key: String, defaultValue: Int = 0) -> Int {
        return Int(mmkv?.int32(forKey: key) ?? Int32(defaultValue))
    }
    
    func int64(forKey key: String, defaultValue: Int64 = 0) -> Int64 {
        return mmkv?.int64(forKey: key) ?? defaultValue
    }
    
    func double(forKey key: String, defaultValue: Double = 0.0) -> Double {
        return mmkv?.double(forKey: key) ?? defaultValue
    }
    
    func string(forKey key: String, defaultValue: String = "") -> String {
        return mmkv?.string(forKey: key) ?? defaultValue
    }
    
    func data(forKey key: String) -> Data? {
        return mmkv?.data(forKey: key)
    }
    
    func remove(forKey key: String) {
        mmkv?.removeValue(forKey: key)
    }
    
    func clearAll() {
        mmkv?.clearAll()
        print("🗑️ MMKV 所有数据已清空")
    }
    
    func allKeys() -> [String] {
        return mmkv?.allKeys() as? [String] ?? []
    }
    
    // MARK: - 数据迁移
    
    /// 从 UserDefaults 迁移数据（仅首次启动时执行一次）
    private func migrateFromUserDefaultsIfNeeded() {
        let migrationKey = "_mmkv_migration_completed"
        
        // 检查是否已经迁移过
        if bool(forKey: migrationKey) {
            return
        }
        
        print("🔄 开始从 UserDefaults 迁移数据到 MMKV...")
        
        let ud = UserDefaults.standard
        var migratedCount = 0
        
        // 迁移已有数据
        let keysToMigrate = [
            "HasImportedWordLists",
            "current_list_id",
            "is_typing_practice_mode",
            "status_bar_show_phonetic",
            "status_bar_max_length",
            "floating_panel_alpha",
            "daily_goal"
        ]
        
        for key in keysToMigrate {
            if let value = ud.object(forKey: key) {
                switch value {
                case let v as Bool:
                    set(v, forKey: key)
                case let v as Int:
                    set(v, forKey: key)
                case let v as Double:
                    set(v, forKey: key)
                case let v as String:
                    set(v, forKey: key)
                case let v as Data:
                    set(v, forKey: key)
                default:
                    continue
                }
                
                // 从 UserDefaults 中删除
                ud.removeObject(forKey: key)
                migratedCount += 1
            }
        }
        
        ud.synchronize()
        
        // 标记迁移完成
        set(true, forKey: migrationKey)
        
        print("✅ 数据迁移完成，共迁移 \(migratedCount) 个配置项")
    }
}



// MARK: - 便捷访问方法

extension LLMMKVManager {
    
    // MARK: - UI 设置
    
    /// 主题模式（auto/light/dark）
    var themeMode: String {
        get { string(forKey: LLMMKVKeys.themeMode, defaultValue: "auto") }
        set { set(newValue, forKey: LLMMKVKeys.themeMode) }
    }
    
    /// 字体大小
    var fontSize: Double {
        get { double(forKey: LLMMKVKeys.fontSize, defaultValue: 14.0) }
        set { set(newValue, forKey: LLMMKVKeys.fontSize) }
    }
    
    /// 侧边栏是否展开
    var sidebarExpanded: Bool {
        get { bool(forKey: LLMMKVKeys.sidebarExpanded, defaultValue: true) }
        set { set(newValue, forKey: LLMMKVKeys.sidebarExpanded) }
    }
    
    /// 侧边栏宽度
    var sidebarWidth: Double {
        get { double(forKey: LLMMKVKeys.sidebarWidth, defaultValue: 250.0) }
        set { set(newValue, forKey: LLMMKVKeys.sidebarWidth) }
    }
    
    /// 窗口位置和大小（NSRect 转 Data 存储）
    var windowFrame: NSRect? {
        get {
            guard let data = data(forKey: LLMMKVKeys.windowFrame) else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSValue.self, from: data)?.rectValue
        }
        set {
            if let rect = newValue {
                let value = NSValue(rect: rect)
                if let data = try? NSKeyedArchiver.archivedData(withRootObject: value, requiringSecureCoding: true) {
                    set(data, forKey: LLMMKVKeys.windowFrame)
                }
            } else {
                remove(forKey: LLMMKVKeys.windowFrame)
            }
        }
    }
    
    // MARK: - 学习设置
    
    /// 当前选中的词库 ID
    var currentListId: String? {
        get {
            let value = string(forKey: LLMMKVKeys.currentListId)
            return value.isEmpty ? nil : value
        }
        set {
            if let value = newValue {
                set(value, forKey: LLMMKVKeys.currentListId)
            } else {
                remove(forKey: LLMMKVKeys.currentListId)
            }
        }
    }
    
    /// 是否处于打字练习模式
    var isTypingPracticeMode: Bool {
        get { bool(forKey: LLMMKVKeys.isTypingPracticeMode, defaultValue: false) }
        set { set(newValue, forKey: LLMMKVKeys.isTypingPracticeMode) }
    }
    
    /// 每日学习目标（单词数）
    var dailyGoal: Int {
        get { int(forKey: LLMMKVKeys.dailyGoal, defaultValue: 50) }
        set { set(newValue, forKey: LLMMKVKeys.dailyGoal) }
    }
    
    /// 是否自动播放音频
    var autoPlayAudio: Bool {
        get { bool(forKey: LLMMKVKeys.autoPlayAudio, defaultValue: false) }
        set { set(newValue, forKey: LLMMKVKeys.autoPlayAudio) }
    }
    
    /// 复习间隔（小时）
    var reviewInterval: Int {
        get { int(forKey: LLMMKVKeys.reviewInterval, defaultValue: 24) }
        set { set(newValue, forKey: LLMMKVKeys.reviewInterval) }
    }
    
    // MARK: - 显示设置
    
    /// 状态栏是否显示音标
    var statusBarShowPhonetic: Bool {
        get { bool(forKey: LLMMKVKeys.statusBarShowPhonetic, defaultValue: true) }
        set { set(newValue, forKey: LLMMKVKeys.statusBarShowPhonetic) }
    }
    
    /// 状态栏是否显示释义
    var statusBarShowMeaning: Bool {
        get { bool(forKey: LLMMKVKeys.statusBarShowMeaning, defaultValue: false) }
        set { set(newValue, forKey: LLMMKVKeys.statusBarShowMeaning) }
    }
    
    /// 状态栏最大显示长度
    var statusBarMaxLength: Int {
        get { int(forKey: LLMMKVKeys.statusBarMaxLength, defaultValue: 20) }
        set { set(newValue, forKey: LLMMKVKeys.statusBarMaxLength) }
    }
    
    /// 浮动窗口透明度
    var floatingPanelAlpha: Double {
        get { double(forKey: LLMMKVKeys.floatingPanelAlpha, defaultValue: 0.95) }
        set { set(newValue, forKey: LLMMKVKeys.floatingPanelAlpha) }
    }
    
    /// 是否显示反馈按钮
    var showFeedbackButtons: Bool {
        get { bool(forKey: LLMMKVKeys.showFeedbackButtons, defaultValue: true) }
        set { set(newValue, forKey: LLMMKVKeys.showFeedbackButtons) }
    }
    
    // MARK: - 导入相关
    
    /// 是否已导入词库列表
    var hasImportedWordLists: Bool {
        get { bool(forKey: LLMMKVKeys.hasImportedWordLists, defaultValue: false) }
        set { set(newValue, forKey: LLMMKVKeys.hasImportedWordLists) }
    }
    
    /// 最后导入时间
    var lastImportTime: Date? {
        get {
            let timestamp = double(forKey: LLMMKVKeys.lastImportTime)
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
        set {
            if let date = newValue {
                set(date.timeIntervalSince1970, forKey: LLMMKVKeys.lastImportTime)
            } else {
                remove(forKey: LLMMKVKeys.lastImportTime)
            }
        }
    }
    
    /// 最后导入的版本号
    var lastImportVersion: String? {
        get {
            let value = string(forKey: LLMMKVKeys.lastImportVersion)
            return value.isEmpty ? nil : value
        }
        set {
            if let value = newValue {
                set(value, forKey: LLMMKVKeys.lastImportVersion)
            } else {
                remove(forKey: LLMMKVKeys.lastImportVersion)
            }
        }
    }
    
    // MARK: - 统计相关
    
    /// 总学习单词数
    var totalLearnedWords: Int {
        get { int(forKey: LLMMKVKeys.totalLearnedWords, defaultValue: 0) }
        set { set(newValue, forKey: LLMMKVKeys.totalLearnedWords) }
    }
    
    /// 总学习时长（秒）
    var totalStudyTime: Int64 {
        get { int64(forKey: LLMMKVKeys.totalStudyTime, defaultValue: 0) }
        set { set(newValue, forKey: LLMMKVKeys.totalStudyTime) }
    }
    
    /// 连续学习天数
    var continuousStudyDays: Int {
        get { int(forKey: LLMMKVKeys.continuousStudyDays, defaultValue: 0) }
        set { set(newValue, forKey: LLMMKVKeys.continuousStudyDays) }
    }
    
    /// 最后学习日期
    var lastStudyDate: Date? {
        get {
            let timestamp = double(forKey: LLMMKVKeys.lastStudyDate)
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
        set {
            if let date = newValue {
                set(date.timeIntervalSince1970, forKey: LLMMKVKeys.lastStudyDate)
            } else {
                remove(forKey: LLMMKVKeys.lastStudyDate)
            }
        }
    }
    
    // MARK: - 其他
    
    /// 是否已经启动过应用
    var hasLaunched: Bool {
        get { bool(forKey: LLMMKVKeys.hasLaunched, defaultValue: false) }
        set { set(newValue, forKey: LLMMKVKeys.hasLaunched) }
    }
    
    /// 首次启动日期
    var firstLaunchDate: Date? {
        get {
            let timestamp = double(forKey: LLMMKVKeys.firstLaunchDate)
            if timestamp > 0 {
                return Date(timeIntervalSince1970: timestamp)
            } else {
                // 首次启动，记录当前时间
                let now = Date()
                self.firstLaunchDate = now
                return now
            }
        }
        set {
            if let date = newValue {
                set(date.timeIntervalSince1970, forKey: LLMMKVKeys.firstLaunchDate)
            }
        }
    }
    
    /// 应用版本号
    var appVersion: String {
        get { string(forKey: LLMMKVKeys.appVersion, defaultValue: "1.0.0") }
        set { set(newValue, forKey: LLMMKVKeys.appVersion) }
    }
    
    /// 用户语言
    var userLanguage: String {
        get { string(forKey: LLMMKVKeys.userLanguage, defaultValue: "zh-Hans") }
        set { set(newValue, forKey: LLMMKVKeys.userLanguage) }
    }
}

// MARK: - 调试方法

extension LLMMKVManager {
    
    /// 打印所有配置（用于调试）
    func printAllConfigs() {
        print("\n" + String(repeating: "=", count: 60))
        print("📋 MMKV 所有配置：")
        print(String(repeating: "=", count: 60))
        
        let keys = allKeys().sorted()
        for key in keys {
            if let value = mmkv?.object(of: NSObject.self, forKey: key) {
                print("  \(key): \(value)")
            }
        }
        
        print(String(repeating: "=", count: 60) + "\n")
    }
    
    /// 导出配置为字典（用于备份）
    func exportConfigs() -> [String: Any] {
        var configs: [String: Any] = [:]
        
        for key in allKeys() {
            if let value = mmkv?.object(of: NSObject.self, forKey: key) {
                configs[key] = value
            }
        }
        
        return configs
    }
}

