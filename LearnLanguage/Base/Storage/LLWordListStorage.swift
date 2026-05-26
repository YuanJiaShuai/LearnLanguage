//
//  LLWordListStorage.swift
//  LearnLanguage
//
//  词库存储适配器 - 统一使用数据库

import Foundation

/// 词库存储（数据库适配器）
final class LLWordListStorage {
    static let shared = LLWordListStorage()
    
    static let vocabularyNotebookDescription = "__system_vocabulary_notebook__"
    static let vocabularyNotebookName = "生词本"
    
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
    
    func ensureVocabularyNotebook(language: LLLearningLanguage) -> WordList? {
        do {
            if let existing = try LLDatabaseManager.shared.getWordList(description: Self.vocabularyNotebookDescription) {
                return convertToWordList(existing)
            }
            
            let categories = try LLDatabaseManager.shared.getAllCategories()
            let fallbackCategoryId = categories.first?.id
            let notebook = LLDBWordList(
                categoryId: fallbackCategoryId,
                name: Self.vocabularyNotebookName,
                description: Self.vocabularyNotebookDescription
            )
            notebook.totalWords = 0
            let insertedId = try LLDatabaseManager.shared.insertWordList(notebook)
            
            NotificationCenter.default.post(name: .learnLanguageReloadWordLists, object: nil)
            return WordList(
                id: String(insertedId),
                name: Self.vocabularyNotebookName,
                category: "内置",
                language: language,
                entries: [],
                totalWords: 0,
                isVocabularyNotebook: true
            )
        } catch {
            LLLogger.error("❌ 创建生词本失败：\(error)")
            return nil
        }
    }
    
    func vocabularyNotebook(language: LLLearningLanguage) -> WordList? {
        if let notebook = ensureVocabularyNotebook(language: language) {
            return list(byId: notebook.id)
        }
        return nil
    }
    
    func containsWordInVocabularyNotebook(_ text: String, language: LLLearningLanguage) -> Bool {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty,
              let notebook = ensureVocabularyNotebook(language: language),
              let notebookId = Int(notebook.id) else {
            return false
        }
        
        do {
            return try LLDatabaseManager.shared.getWord(inWordListId: notebookId, word: normalizedText) != nil
        } catch {
            LLLogger.error("❌ 查询生词失败：\(error)")
            return false
        }
    }
    
    @discardableResult
    func addWordToVocabularyNotebook(text: String, meaning: String, phonetic: String?, language: LLLearningLanguage) -> Bool {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedMeaning = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedText.isEmpty, !normalizedMeaning.isEmpty,
              let notebook = ensureVocabularyNotebook(language: language),
              let notebookId = Int(notebook.id) else {
            return false
        }
        
        do {
            if try LLDatabaseManager.shared.getWord(inWordListId: notebookId, word: normalizedText) != nil {
                return false
            }
            
            let dbWord = LLDBWord(
                wordListId: notebookId,
                word: normalizedText,
                translation: normalizedMeaning,
                usPhonetic: phonetic,
                ukPhonetic: nil
            )
            try LLDatabaseManager.shared.insertWord(dbWord)
            
            let totalCount = try LLDatabaseManager.shared.getWordCount(forWordListId: notebookId)
            let learnedCount = try LLDatabaseManager.shared.getLearnedWordCount(forWordListId: notebookId)
            try LLDatabaseManager.shared.updateWordListStats(id: notebookId, totalWords: totalCount, learnedWords: learnedCount)
            
            NotificationCenter.default.post(name: .learnLanguageReloadWordLists, object: nil)
            return true
        } catch {
            LLLogger.error("❌ 添加生词失败：\(error)")
            return false
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
            try LLDatabaseManager.shared.deleteLearningHistory(wordListId: id)
            try LLDatabaseManager.shared.deleteLearningProgress(wordListId: id)
            
            // 先删除单词
            try LLDatabaseManager.shared.deleteWords(forWordListId: numericId)
            
            // 再删除词库
            try LLDatabaseManager.shared.deleteWordList(id: numericId)
            
            if LLSettingsStore.shared.currentListId == id {
                LLSettingsStore.shared.currentListId = nil
            }
            
            LLLogger.info("✅ 词库删除成功")
            
            // 发送通知
            NotificationCenter.default.post(name: .learnLanguageReloadWordLists, object: nil)
            NotificationCenter.default.post(name: .learnLanguageRefreshStatus, object: nil)
            
        } catch {
            LLLogger.error("❌ 删除词库失败：\(error)")
        }
    }
    
    // MARK: - 辅助方法
    
    /// 将数据库词库对象转换为 WordList
    private func convertToWordList(_ dbWordList: LLDBWordList, words: [LLDBWord]? = nil) -> WordList? {
        guard let id = dbWordList.id else { return nil }
        
        // 获取分类名称
        var categoryName = "未分类"
        if dbWordList.description == Self.vocabularyNotebookDescription {
            categoryName = "内置"
        } else if let categoryId = dbWordList.categoryId,
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
                    wordListId: "\(dbWord.wordListId)",
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
            totalWords: dbWordList.totalWords,
            isVocabularyNotebook: dbWordList.description == Self.vocabularyNotebookDescription
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
