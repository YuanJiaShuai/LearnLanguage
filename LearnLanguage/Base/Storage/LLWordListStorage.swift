//
//  LLWordListStorage.swift
//  LearnLanguage
//
//  词库存储适配器 - 统一使用数据库

import Foundation

/// 词库存储（数据库适配器）
final class LLWordListStorage {
    static let shared = LLWordListStorage()
    
    private init() {}
    
    // MARK: - 词库查询
    
    /// 获取所有词库
    func allLists() -> [WordList] {
        do {
            let dbWordLists = try LLDatabaseManager.shared.getAllWordLists()
            return dbWordLists.compactMap { convertToWordList($0) }
        } catch {
            LLLogger.error("❌ 获取词库列表失败：\(error)")
            return []
        }
    }
    
    /// 根据 ID 获取词库
    func list(byId id: String) -> WordList? {
        // 尝试解析 ID（可能是数字 ID 或字符串 ID）
        guard let numericId = Int(id) else {
            LLLogger.error("❌ 无效的词库 ID：\(id)")
            return nil
        }
        
        do {
            guard let dbWordList = try LLDatabaseManager.shared.getWordList(id: numericId) else {
                return nil
            }
            
            // 获取单词数据
            let dbWords = try LLDatabaseManager.shared.getWords(forWordListId: numericId)
            return convertToWordList(dbWordList, words: dbWords)
        } catch {
            LLLogger.error("❌ 获取词库失败：\(error)")
            return nil
        }
    }
    
    /// 根据分类获取词库
    func lists(byCategory category: String) -> [WordList] {
        do {
            let categories = try LLDatabaseManager.shared.getAllCategories()
            guard let dbCategory = categories.first(where: { $0.name == category }),
                  let categoryId = dbCategory.id else {
                return []
            }
            
            let dbWordLists = try LLDatabaseManager.shared.getWordListByCategoryId(categoryId)
            return dbWordLists.compactMap { convertToWordList($0) }
        } catch {
            LLLogger.error("❌ 获取分类词库失败：\(error)")
            return []
        }
    }
    
    // MARK: - 词库操作
    
    /// 添加词库
    func addList(_ list: WordList) {
        do {
            // 获取分类 ID
            let categories = try LLDatabaseManager.shared.getAllCategories()
            let categoryId = categories.first(where: { $0.name == list.category })?.id
            
            // 创建数据库词库对象
            let dbWordList = LLDBWordList(
                categoryId: categoryId,
                name: list.name,
                description: nil
            )
            dbWordList.totalWords = list.entries.count
            
            // 插入词库
            let listId = try LLDatabaseManager.shared.insertWordList(dbWordList)
            
            // 插入单词
            let dbWords = list.entries.map { entry -> LLDBWord in
                let word = LLDBWord(
                    wordListId: Int(listId),
                    word: entry.text,
                    translation: entry.meaning,
                    usPhonetic: entry.phonetic,
                    ukPhonetic: nil
                )
                return word
            }
            
            if !dbWords.isEmpty {
                try LLDatabaseManager.shared.insertWords(dbWords)
            }
            
            LLLogger.info("✅ 词库添加成功：\(list.name)")
            
            // 发送通知
            NotificationCenter.default.post(name: .learnLanguageReloadWordLists, object: nil)
            
        } catch {
            LLLogger.error("❌ 添加词库失败：\(error)")
        }
    }
    
    /// 更新词库
    func updateList(_ list: WordList) {
        guard let numericId = Int(list.id) else {
            LLLogger.error("❌ 无效的词库 ID：\(list.id)")
            return
        }
        
        do {
            guard let dbWordList = try LLDatabaseManager.shared.getWordList(id: numericId) else {
                LLLogger.error("❌ 词库不存在：\(list.id)")
                return
            }
            
            dbWordList.name = list.name
            dbWordList.totalWords = list.entries.count
            
            try LLDatabaseManager.shared.updateWordList(dbWordList, on: [.name, .totalWords])
            
            LLLogger.info("✅ 词库更新成功：\(list.name)")
            
            // 发送通知
            NotificationCenter.default.post(name: .learnLanguageReloadWordLists, object: nil)
            
        } catch {
            LLLogger.error("❌ 更新词库失败：\(error)")
        }
    }
    
    /// 删除词库
    func removeList(id: String) {
        guard let numericId = Int(id) else {
            LLLogger.error("❌ 无效的词库 ID：\(id)")
            return
        }
        
        do {
            // 先删除单词
            try LLDatabaseManager.shared.deleteWords(forWordListId: numericId)
            
            // 再删除词库
            try LLDatabaseManager.shared.deleteWordList(id: numericId)
            
            LLLogger.info("✅ 词库删除成功")
            
            // 发送通知
            NotificationCenter.default.post(name: .learnLanguageReloadWordLists, object: nil)
            
        } catch {
            LLLogger.error("❌ 删除词库失败：\(error)")
        }
    }
    
    // MARK: - 导入导出
    
    /// 从 JSON 文件导入词库
    func importFromFile(url: URL, listName: String, language: LLLearningLanguage, category: String = "未分类") -> WordList? {
        guard let data = try? Data(contentsOf: url),
              let json = Self.parseWordArray(from: data) else {
            return nil
        }
        
        var entries: [LLWordEntry] = []
        for item in json {
            let name = item["name"] as? String ?? item["word"] as? String ?? ""
            let trans: String
            if let arr = item["trans"] as? [String], !arr.isEmpty {
                trans = arr.joined(separator: "；")
            } else {
                trans = item["trans"] as? String ?? item["meaning"] as? String ?? ""
            }
            let us = item["usphone"] as? String
            let uk = item["ukphone"] as? String
            let phonetic = [us, uk].compactMap { $0 }.filter { !$0.isEmpty }.first
            
            if !name.isEmpty {
                entries.append(LLWordEntry(text: name, meaning: trans, phonetic: phonetic, language: language))
            }
        }
        
        guard !entries.isEmpty else { return nil }
        
        let list = WordList(
            id: UUID().uuidString, // 临时 ID，添加后会被替换
            name: listName,
            category: category,
            language: language,
            entries: entries
        )
        
        addList(list)
        return list
    }
    
    /// 导出数据（供备份）
    func exportData(learningRecords: [LLLearningRecord]) -> Data? {
        let allLists = self.allLists()
        
        let payload: [String: Any] = [
            "wordLists": allLists.map { list in
                [
                    "id": list.id,
                    "name": list.name,
                    "category": list.category,
                    "language": list.language.rawValue,
                    "createdAt": list.createdAt.timeIntervalSince1970,
                    "entries": list.entries.map { e in
                        [
                            "id": e.id,
                            "text": e.text,
                            "meaning": e.meaning,
                            "phonetic": e.phonetic as Any
                        ] as [String: Any]
                    } as [[String: Any]]
                ] as [String: Any]
            } as [[String: Any]],
            "learningRecords": learningRecords.map { r in
                [
                    "wordId": r.wordId,
                    "listId": r.listId,
                    "feedback": r.feedback.rawValue,
                    "lastSeenAt": r.lastSeenAt.timeIntervalSince1970,
                    "nextReviewAt": r.nextReviewAt?.timeIntervalSince1970 as Any
                ] as [String: Any]
            } as [[String: Any]],
            "exportedAt": Date().timeIntervalSince1970
        ]
        
        return try? JSONSerialization.data(withJSONObject: payload)
    }
    
    /// 从备份恢复
    func restoreFromData(_ data: Data) -> Bool {
        struct ExportEntry: Codable {
            let id: String?
            let text: String
            let meaning: String
            let phonetic: String?
        }
        struct ExportList: Codable {
            let id: String?
            let name: String
            let category: String?
            let language: String
            let createdAt: Double?
            let entries: [ExportEntry]
        }
        struct ExportRoot: Codable {
            let wordLists: [ExportList]
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        guard let root = try? decoder.decode(ExportRoot.self, from: data) else {
            return false
        }
        
        for el in root.wordLists {
            let lang = LLLearningLanguage(rawValue: el.language) ?? .english
            let entries = el.entries.map { e in
                LLWordEntry(
                    id: UUID().uuidString,
                    text: e.text,
                    meaning: e.meaning,
                    phonetic: e.phonetic,
                    language: lang
                )
            }
            
            let list = WordList(
                id: UUID().uuidString,
                name: el.name,
                category: el.category ?? "未分类",
                language: lang,
                entries: entries,
                createdAt: el.createdAt.map { Date(timeIntervalSince1970: $0) } ?? Date()
            )
            
            addList(list)
        }
        
        return true
    }
    
    // MARK: - 辅助方法
    
    /// 将数据库词库对象转换为 WordList
    private func convertToWordList(_ dbWordList: LLDBWordList, words: [LLDBWord]? = nil) -> WordList? {
        guard let id = dbWordList.id else { return nil }
        
        // 获取分类名称
        var categoryName = "未分类"
        if let categoryId = dbWordList.categoryId,
           let category = try? LLDatabaseManager.shared.getCategoryById(categoryId) {
            categoryName = category.name
        }
        
        // 转换单词
        let entries: [LLWordEntry]
        if let dbWords = words {
            let accent = LLSettingsStore.shared.settings.pronunciationAccent
            entries = dbWords.map { dbWord in
                // 根据发音口音设置选择对应音标，没有则回退到另一种
                let phonetic: String?
                switch accent {
                case .uk:
                    phonetic = dbWord.ukPhonetic ?? dbWord.usPhonetic
                case .us:
                    phonetic = dbWord.usPhonetic ?? dbWord.ukPhonetic
                }
                return LLWordEntry(
                    id: "\(dbWord.id ?? 0)",
                    text: dbWord.word,
                    meaning: dbWord.translation,
                    phonetic: phonetic,
                    language: .english // TODO: 从词库获取语言
                )
            }
        } else {
            entries = []
        }
        
        return WordList(
            id: "\(id)",
            name: dbWordList.name,
            category: categoryName,
            language: .english, // TODO: 从词库获取语言
            entries: entries,
            createdAt: Date(timeIntervalSince1970: dbWordList.createdAt),
            totalWords: dbWordList.totalWords
        )
    }
    
    /// 解析 JSON 数据
    private static func parseWordArray(from data: Data) -> [[String: Any]]? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) else { return nil }
        
        if let arr = obj as? [[String: Any]] {
            return arr
        }
        
        if let dict = obj as? [String: Any] {
            let keys = ["words", "list", "items"]
            for key in keys {
                if let arr = dict[key] as? [[String: Any]] {
                    return arr
                }
            }
        }
        
        return nil
    }
}
