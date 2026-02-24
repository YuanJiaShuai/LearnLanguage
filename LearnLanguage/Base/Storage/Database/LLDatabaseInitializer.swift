//
//  LLDatabaseInitializer.swift
//  LearnLanguage
//
//  数据库初始化管理器
//  负责首次安装、版本检查和增量更新
//

import Foundation
import WCDBSwift

final class LLDatabaseInitializer {
    
    static let shared = LLDatabaseInitializer()
    
    // 数据库版本号（自动跟随 App 版本号）
    private var currentDBVersion: Int {
        guard let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
              let versionNumber = Int(version) else {
            return 1 // 默认版本号
        }
        return versionNumber
    }
    
    // 版本号存储key
    private let versionKey = "database_version"
    
    // Resources 中的数据库文件名
    private let resourceDBName = "LearnLanguage.db"
    
    // 本地数据库路径
    private var localDBPath: String {
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return documentPath + "/LearnLanguage.db"
    }
    
    // Resources 中的数据库路径
    private var resourceDBPath: String? {
        return Bundle.main.path(forResource: "LearnLanguage", ofType: "db")
    }
    
    private init() {}
    
    // MARK: - 公开方法
    
    /// 初始化数据库（在 App 启动时调用）
    func initializeDatabase() {
        print("\n" + String(repeating: "=", count: 60))
        print("🗄️ 开始数据库初始化...")
        print(String(repeating: "=", count: 60))
        
        let fileManager = FileManager.default
        let localExists = fileManager.fileExists(atPath: localDBPath)
        
        if !localExists {
            // 首次安装：直接复制数据库
            print("📦 首次安装，复制数据库文件...")
            copyDatabaseFromResources()
            saveCurrentVersion()
        } else {
            // 检查版本号
            let savedVersion = getSavedVersion()
            print("📊 本地数据库版本：\(savedVersion)")
            print("📊 资源数据库版本：\(currentDBVersion)")
            
            if savedVersion < currentDBVersion {
                // 需要更新
                print("🔄 检测到数据库更新，开始增量更新...")
                performIncrementalUpdate(from: savedVersion, to: currentDBVersion)
                saveCurrentVersion()
            } else {
                print("✅ 数据库已是最新版本")
            }
        }
        
        print(String(repeating: "=", count: 60))
        print("✅ 数据库初始化完成")
        print(String(repeating: "=", count: 60) + "\n")
    }
    
    // MARK: - 私有方法
    
    /// 从 Resources 复制数据库到本地
    private func copyDatabaseFromResources() {
        guard let resourcePath = resourceDBPath else {
            print("❌ 错误：找不到 Resources 中的数据库文件")
            return
        }
        
        let fileManager = FileManager.default
        
        do {
            // 如果本地已存在，先删除（包括 WAL 相关文件）
            if fileManager.fileExists(atPath: localDBPath) {
                try fileManager.removeItem(atPath: localDBPath)
            }
            
            // 删除可能存在的 WAL 和 SHM 文件
            let walPath = localDBPath + "-wal"
            let shmPath = localDBPath + "-shm"
            if fileManager.fileExists(atPath: walPath) {
                try? fileManager.removeItem(atPath: walPath)
            }
            if fileManager.fileExists(atPath: shmPath) {
                try? fileManager.removeItem(atPath: shmPath)
            }
            
            // 复制文件
            try fileManager.copyItem(atPath: resourcePath, toPath: localDBPath)
            
            // 设置文件为可读写
            try fileManager.setAttributes([.posixPermissions: 0o666], ofItemAtPath: localDBPath)
            
            print("✅ 数据库文件复制成功")
            print("   源路径：\(resourcePath)")
            print("   目标路径：\(localDBPath)")
            
        } catch {
            print("❌ 复制数据库文件失败：\(error)")
        }
    }
    
    /// 执行增量更新
    private func performIncrementalUpdate(from oldVersion: Int, to newVersion: Int) {
        guard let resourcePath = resourceDBPath else {
            print("❌ 错误：找不到 Resources 中的数据库文件")
            return
        }
        
        do {
            // 打开本地数据库
            let localDB = Database(withPath: localDBPath)
            
            // 打开资源数据库
            let resourceDB = Database(withPath: resourcePath)
            
            print("\n📝 开始增量更新...")
            
            // 1. 更新分类
            try updateCategories(from: resourceDB, to: localDB)
            
            // 2. 更新词库列表
            try updateWordLists(from: resourceDB, to: localDB)
            
            // 3. 更新单词数据
            try updateWords(from: resourceDB, to: localDB)
            
            print("✅ 增量更新完成\n")
            
        } catch {
            print("❌ 增量更新失败：\(error)")
        }
    }
    
    /// 更新分类数据
    private func updateCategories(from sourceDB: Database, to targetDB: Database) throws {
        print("\n📂 更新分类数据...")
        
        let tableName = "categories"
        
        // 获取资源数据库中的所有分类
        let sourceCategories: [LLDBWordListCategory] = try sourceDB.getObjects(
            on: LLDBWordListCategory.Properties.all,
            fromTable: tableName
        )
        
        // 获取本地数据库中已有的分类名称
        let existingCategories: [LLDBWordListCategory] = try targetDB.getObjects(
            on: LLDBWordListCategory.Properties.all,
            fromTable: tableName
        )
        let existingNames = Set(existingCategories.map { $0.name })
        
        // 筛选出新增的分类
        let newCategories = sourceCategories.filter { !existingNames.contains($0.name) }
        
        if !newCategories.isEmpty {
            try targetDB.insert(objects: newCategories, intoTable: tableName)
            print("   ✅ 新增 \(newCategories.count) 个分类")
            for category in newCategories {
                print("      - \(category.name)")
            }
        } else {
            print("   ⏭️ 没有新增分类")
        }
    }
    
    /// 更新词库列表数据
    private func updateWordLists(from sourceDB: Database, to targetDB: Database) throws {
        print("\n📚 更新词库列表...")
        
        let tableName = "word_lists"
        
        // 获取资源数据库中的所有词库
        let sourceWordLists: [LLDBWordList] = try sourceDB.getObjects(
            on: LLDBWordList.Properties.all,
            fromTable: tableName
        )
        
        // 获取本地数据库中已有的词库 categoryId
        let existingWordLists: [LLDBWordList] = try targetDB.getObjects(
            on: LLDBWordList.Properties.all,
            fromTable: tableName
        )
        let existingIds = Set(existingWordLists.compactMap { $0.categoryId })
        
        // 筛选出新增的词库（根据 categoryId 判断）
        let newWordLists = sourceWordLists.filter { wordList in
            guard let categoryId = wordList.categoryId else { return false }
            return !existingIds.contains(categoryId)
        }
        
        if !newWordLists.isEmpty {
            // 重置 id 为 nil，让数据库自动分配
            for wordList in newWordLists {
                wordList.id = nil
            }
            
            try targetDB.insert(objects: newWordLists, intoTable: tableName)
            print("   ✅ 新增 \(newWordLists.count) 个词库")
            
            // 显示前10个
            for (index, wordList) in newWordLists.prefix(10).enumerated() {
                print("      \(index + 1). \(wordList.name) (\(wordList.totalWords) 词)")
            }
            if newWordLists.count > 10 {
                print("      ... 还有 \(newWordLists.count - 10) 个词库")
            }
        } else {
            print("   ⏭️ 没有新增词库")
        }
    }
    
    /// 更新单词数据
    private func updateWords(from sourceDB: Database, to targetDB: Database) throws {
        print("\n📖 更新单词数据...")
        
        let wordListTable = "word_lists"
        let wordsTable = "words"
        
        // 获取本地数据库中的所有词库
        let localWordLists: [LLDBWordList] = try targetDB.getObjects(
            on: LLDBWordList.Properties.all,
            fromTable: wordListTable
        )
        
        // 获取资源数据库中的所有词库
        let sourceWordLists: [LLDBWordList] = try sourceDB.getObjects(
            on: LLDBWordList.Properties.all,
            fromTable: wordListTable
        )
        
        // 创建 categoryId 到 id 的映射
        var sourceCategoryToId: [Int: Int] = [:]
        for wordList in sourceWordLists {
            if let categoryId = wordList.categoryId, let id = wordList.id {
                sourceCategoryToId[categoryId] = id
            }
        }
        
        var totalNewWords = 0
        var updatedWordListCount = 0
        
        // 遍历本地词库，检查是否需要导入单词
        for localWordList in localWordLists {
            guard let localId = localWordList.id,
                  let categoryId = localWordList.categoryId,
                  let sourceId = sourceCategoryToId[categoryId] else {
                continue
            }
            
            // 检查本地词库是否已有单词
            let localWordCount = try targetDB.getValue(
                on: LLDBWord.Properties.id.count(),
                fromTable: wordsTable,
                where: LLDBWord.Properties.wordListId == localId
            ).int32Value
            
            // 如果本地没有单词，从资源数据库导入
            if localWordCount == 0 {
                // 从资源数据库获取单词
                let sourceWords: [LLDBWord] = try sourceDB.getObjects(
                    on: LLDBWord.Properties.all,
                    fromTable: wordsTable,
                    where: LLDBWord.Properties.wordListId == sourceId
                )
                
                if !sourceWords.isEmpty {
                    // 更新 wordListId 为本地 id，并重置 id
                    for word in sourceWords {
                        word.id = nil
                        word.wordListId = localId
                    }
                    
                    // 插入到本地数据库
                    try targetDB.insert(objects: sourceWords, intoTable: wordsTable)
                    
                    totalNewWords += sourceWords.count
                    updatedWordListCount += 1
                    
                    if updatedWordListCount <= 5 {
                        print("   ✅ \(localWordList.name): 导入 \(sourceWords.count) 个单词")
                    }
                }
            }
        }
        
        if totalNewWords > 0 {
            print("   ✅ 共为 \(updatedWordListCount) 个词库导入了 \(totalNewWords) 个单词")
        } else {
            print("   ⏭️ 没有需要导入的单词")
        }
    }
    
    // MARK: - 版本管理
    
    /// 获取已保存的数据库版本号
    private func getSavedVersion() -> Int {
        return UserDefaults.standard.integer(forKey: versionKey)
    }
    
    /// 保存当前数据库版本号
    private func saveCurrentVersion() {
        UserDefaults.standard.set(currentDBVersion, forKey: versionKey)
        UserDefaults.standard.synchronize()
        print("💾 已保存数据库版本号：\(currentDBVersion)")
    }
    
    // MARK: - 工具方法
    
    /// 强制重新初始化数据库（用于测试）
    func forceReinitialize() {
        print("\n⚠️ 强制重新初始化数据库...")
        
        let fileManager = FileManager.default
        
        // 删除本地数据库
        if fileManager.fileExists(atPath: localDBPath) {
            try? fileManager.removeItem(atPath: localDBPath)
            print("   🗑️ 已删除本地数据库")
        }
        
        // 清除版本号
        UserDefaults.standard.removeObject(forKey: versionKey)
        UserDefaults.standard.synchronize()
        print("   🗑️ 已清除版本号")
        
        // 重新初始化
        initializeDatabase()
    }
    
    /// 获取数据库统计信息
    func getDatabaseStats() {
        do {
            // 使用 LLDatabaseManager 已经打开的数据库连接
            let db = LLDatabaseManager.shared
            
            let categoryCount = try db.database.getValue(
                on: LLDBWordListCategory.Properties.id.count(),
                fromTable: "categories"
            ).int32Value
            
            let wordListCount = try db.database.getValue(
                on: LLDBWordList.Properties.id.count(),
                fromTable: "word_lists"
            ).int32Value
            
            let wordCount = try db.database.getValue(
                on: LLDBWord.Properties.id.count(),
                fromTable: "words"
            ).int32Value
            
            print("\n📊 数据库统计信息：")
            print("   - 分类数：\(categoryCount)")
            print("   - 词库数：\(wordListCount)")
            print("   - 单词数：\(wordCount)")
            print("   - 版本号：\(getSavedVersion())\n")
            
        } catch {
            print("❌ 获取统计信息失败：\(error)")
        }
    }
}

