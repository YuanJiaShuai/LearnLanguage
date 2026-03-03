//
//  LLAppInitializer.swift
//  LearnLanguage
//
//  应用初始化管理器
//  统一管理所有初始化操作，便于扩展和维护
//

import Foundation
import AppKit
import UserNotifications

final class LLAppInitializer {
    
    static let shared = LLAppInitializer()
    
    private init() {}
    
    // MARK: - 公开方法
    
    /// 执行应用启动时的所有初始化操作
    func performStartupInitialization() {
        // 0. 初始化日志系统（最优先）
        LLLogger.setup()
        
        LLLogger.info("\n" + String(repeating: "=", count: 60))
        LLLogger.info("🚀 开始应用初始化...")
        LLLogger.info(String(repeating: "=", count: 60))
        
        // 1. 初始化 MMKV（会自动从 UserDefaults 迁移数据）
        initializeMMKV()
        
        // 2. 初始化数据库（首次安装或版本更新）
        initializeDatabase()
        
        // 3. 初始化键盘快捷键
        initializeKeyboardShortcuts()
        
        // 4. 初始化用户设置（如果需要）
        initializeUserSettings()
        
        // 5. 初始化外观设置
        initializeAppearance()
        
        // TODO: 未来可以在这里添加更多初始化操作
        // - 检查更新
        // - 初始化网络服务
        // - 初始化统计分析
        // - 初始化通知服务
        // 等等...
        
        LLLogger.info(String(repeating: "=", count: 60))
        LLLogger.info("✅ 应用初始化完成")
        LLLogger.info(String(repeating: "=", count: 60) + "\n")
    }
    
    // MARK: - 私有初始化方法
    
    /// 初始化 MMKV 存储
    private func initializeMMKV() {
        LLLogger.info("\n📦 初始化 MMKV...")
        _ = LLMMKVManager.shared
        LLLogger.info("✅ MMKV 初始化完成")
    }
    
    /// 初始化数据库
    private func initializeDatabase() {
        LLLogger.info("\n🗄️ 初始化数据库...")
        
        // 1. 先初始化数据库文件（复制、版本检查等）
        LLDatabaseInitializer.shared.initializeDatabase()
        
        // 2. 然后打开数据库连接
        LLDatabaseManager.shared.openDatabase()
        
        // 3. 最后打印数据库统计信息
        LLDatabaseInitializer.shared.getDatabaseStats()
    }
    
    /// 初始化键盘快捷键
    private func initializeKeyboardShortcuts() {
        LLLogger.info("\n⌨️ 初始化键盘快捷键...")
        _ = LLKeyboardShortcutManager.shared
        LLLogger.info("✅ 键盘快捷键初始化完成")
    }
    
    /// 初始化外观设置
    private func initializeAppearance() {
        LLLogger.info("\n🎨 初始化外观设置...")
        // 设置应用跟随系统外观
        LLAppearanceManager.shared.setTheme(.system)
        LLLogger.info("✅ 外观设置初始化完成")
    }
    
    /// 初始化用户设置
    private func initializeUserSettings() {
        LLLogger.info("\n⚙️ 初始化用户设置...")
        
        // 检查是否是首次启动
        let isFirstLaunch = !LLMMKVManager.shared.hasLaunched
        
        if isFirstLaunch {
            LLLogger.info("   🎉 首次启动，设置默认配置...")
            
            // 设置默认词库（如果有的话）
            setDefaultWordList()
            
            // 标记已启动
            LLMMKVManager.shared.hasLaunched = true
            LLMMKVManager.shared.firstLaunchDate = Date()
            
            LLLogger.info("   ✅ 默认配置已设置")
        } else {
            LLLogger.info("   ℹ️ 非首次启动，跳过默认配置")
        }
    }
    
    /// 设置默认词库
    private func setDefaultWordList() {
        // 尝试获取第一个词库作为默认词库
        do {
            let db = LLDatabaseManager.shared
            let wordLists = try db.getAllWordLists()
            
            if let firstList = wordLists.first, let id = firstList.id {
                LLSettingsStore.shared.currentListId = String(id)
            }
        } catch {
            LLLogger.warn("   ⚠️ 设置默认词库失败：\(error)")
        }
    }
    
    // MARK: - 维护和调试方法
    
    /// 强制重新初始化所有数据（用于测试或重置）
    func forceReinitializeAll() {
        LLLogger.warn("\n⚠️ 强制重新初始化所有数据...")
        
        let alert = NSAlert()
        alert.messageText = "确认重新初始化"
        alert.informativeText = "这将清除所有本地数据并重新初始化。学习进度将会丢失！"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确认")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // 清除数据库
            LLDatabaseInitializer.shared.forceReinitialize()
            
            // 清除学习记录
            clearLearningRecords()
            
            // 清除设置
            clearSettings()
            
            LLLogger.info("✅ 重新初始化完成")
            
            // 显示通知
            showNotification(title: "重新初始化完成", message: "所有数据已重置")
        } else {
            LLLogger.info("❌ 用户取消了重新初始化")
        }
    }
    
    /// 清除学习记录
    private func clearLearningRecords() {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LearnLanguage", isDirectory: true)
        let recordsFile = appSupportURL.appendingPathComponent("learning_records.json")
        
        if fileManager.fileExists(atPath: recordsFile.path) {
            try? fileManager.removeItem(at: recordsFile)
            LLLogger.info("   🗑️ 已清除学习记录")
        }
    }
    
    /// 清除设置
    private func clearSettings() {
        LLMMKVManager.shared.clearAll()
        LLLogger.info("   🗑️ 已清除所有设置")
    }
    
    /// 显示系统通知
    private func showNotification(title: String, message: String) {
        if #available(macOS 10.14, *) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = message
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    LLLogger.warn("⚠️ 通知发送失败：\(error)")
                }
            }
        } else {
            // macOS 10.13 及以下使用旧 API
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = message
            NSUserNotificationCenter.default.deliver(notification)
        }
    }
    
    // MARK: - 数据库维护方法
    
    /// 检查数据库完整性
    func checkDatabaseIntegrity() {
        LLLogger.info("\n🔍 检查数据库完整性...")
        
        do {
            let db = LLDatabaseManager.shared
            
            // 检查分类数量
            let categories = try db.getAllCategories()
            LLLogger.info("   📂 分类数量：\(categories.count)")
            
            // 检查词库数量
            let wordLists = try db.getAllWordLists()
            LLLogger.info("   📚 词库数量：\(wordLists.count)")
            
            // 检查每个分类下的词库数量
            for category in categories {
                guard let categoryId = category.id else { continue }
                let lists = try db.getWordListByCategoryId(categoryId)
                LLLogger.info("   - \(category.name)：\(lists.count) 个词库")
            }
            
            // 检查有单词的词库数量
            var wordListsWithWords = 0
            var totalWords = 0
            
            for wordList in wordLists {
                guard let id = wordList.id else { continue }
                let count = try db.getWordCount(forWordListId: id)
                if count > 0 {
                    wordListsWithWords += 1
                    totalWords += count
                }
            }
            
            LLLogger.info("   📖 有单词的词库：\(wordListsWithWords) / \(wordLists.count)")
            LLLogger.info("   📝 总单词数：\(totalWords)")
            
            if wordListsWithWords == 0 {
                LLLogger.warn("   ⚠️ 警告：没有词库包含单词数据！")
            }
            
            LLLogger.info("✅ 数据库完整性检查完成\n")
            
        } catch {
            LLLogger.error("❌ 数据库完整性检查失败：\(error)\n")
        }
    }
    
    /// 修复数据库（尝试重新导入数据）
    func repairDatabase() {
        LLLogger.info("\n🔧 开始修复数据库...")
        
        let alert = NSAlert()
        alert.messageText = "修复数据库"
        alert.informativeText = "这将尝试从资源文件重新导入缺失的数据。现有数据不会丢失。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "开始修复")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // 强制重新初始化数据库（增量更新）
            LLDatabaseInitializer.shared.initializeDatabase()
            
            // 检查修复结果
            checkDatabaseIntegrity()
            
            showNotification(title: "修复完成", message: "数据库修复操作已完成")
        }
    }
    
    /// 导出数据库统计信息
    func exportDatabaseStats() -> String {
        var stats = "LearnLanguage 数据库统计\n"
        stats += "生成时间：\(Date())\n"
        stats += String(repeating: "=", count: 50) + "\n\n"
        
        do {
            let db = LLDatabaseManager.shared
            
            // 分类统计
            let categories = try db.getAllCategories()
            stats += "分类数量：\(categories.count)\n\n"
            
            for category in categories {
                guard let categoryId = category.id else { continue }
                let lists = try db.getWordListByCategoryId(categoryId)
                stats += "【\(category.name)】\n"
                stats += "  词库数：\(lists.count)\n"
                
                var totalWords = 0
                for list in lists {
                    if let id = list.id {
                        totalWords += try db.getWordCount(forWordListId: id)
                    }
                }
                stats += "  单词数：\(totalWords)\n\n"
            }
            
            // 总计
            let allLists = try db.getAllWordLists()
            var grandTotal = 0
            for list in allLists {
                if let id = list.id {
                    grandTotal += try db.getWordCount(forWordListId: id)
                }
            }
            
            stats += String(repeating: "=", count: 50) + "\n"
            stats += "总词库数：\(allLists.count)\n"
            stats += "总单词数：\(grandTotal)\n"
            
        } catch {
            stats += "错误：\(error)\n"
        }
        
        return stats
    }
}

