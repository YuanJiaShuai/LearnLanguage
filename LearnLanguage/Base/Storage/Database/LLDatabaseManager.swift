//
//  LLDatabaseManager.swift
//  LearnLanguage
//
//  数据库管理类（WCDB）
//

import Foundation
import WCDBSwift

final class LLDatabaseManager {
    
    static let shared = LLDatabaseManager()
    
    private(set) var database: Database!
    private let dbPath: String
    private let wordListsTable = "word_lists"
    private let categoriesTable = "categories"
    private let wordsTable = "words"
    
    private init() {
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        dbPath = documentPath + "/LearnLanguage.db"
        
        print("\n" + String(repeating: "=", count: 60))
        print("📁 数据库路径：")
        print("   \(dbPath)")
        print(String(repeating: "=", count: 60) + "\n")
        
        // 注意：不在这里打开数据库，等待 LLDatabaseInitializer 完成文件准备
        // database = Database(withPath: dbPath)
        // createTables()
        // print("✅ 数据库初始化成功")
    }
    
    /// 打开数据库连接（在数据库文件准备好后调用）
    func openDatabase() {
        guard database == nil else {
            print("⚠️ 数据库已经打开")
            return
        }
        
        database = Database(withPath: dbPath)
        
        // 注意：不需要 createTables()，因为数据库文件已经包含了所有表和数据
        // 只在数据库文件不存在时才需要创建表
        
        print("✅ 数据库连接已打开")
    }
    
    private func createTables() {
        do {
            // 创建分类表
            try database.create(table: categoriesTable, of: LLDBWordListCategory.self)
            print("✅ 分类表创建成功")
            
            // 创建词库表
            try database.create(table: wordListsTable, of: LLDBWordList.self)
            print("✅ 词库表创建成功")
            
            // 创建单词表
            try database.create(table: wordsTable, of: LLDBWord.self)
            print("✅ 单词表创建成功")
            
            // 初始化默认分类
            try initializeDefaultCategories()
            
        } catch {
            print("❌ 创建表失败：\(error)")
        }
    }
    
    // 初始化默认分类
    private func initializeDefaultCategories() throws {
        // 检查是否已经初始化
        let count = try database.getValue(on: LLDBWordListCategory.Properties.id.count(), fromTable: categoriesTable).int32Value
        if count > 0 {
            return // 已经初始化过了
        }
        
        // 创建默认分类
        let categories = [
            LLDBWordListCategory(name: "中国考试", description: "包含四六级、考研等", icon: "graduationcap.fill", color: "#FF6B6B", sortOrder: 1),
            LLDBWordListCategory(name: "国际考试", description: "包含托福、雅思等", icon: "globe", color: "#4ECDC4", sortOrder: 2),
            LLDBWordListCategory(name: "青少年英语", description: "适合青少年学习", icon: "book.fill", color: "#95E1D3", sortOrder: 3),
            LLDBWordListCategory(name: "代码练习", description: "编程相关词汇", icon: "chevron.left.forwardslash.chevron.right", color: "#F38181", sortOrder: 4),
            LLDBWordListCategory(name: "其他语言", description: "其他语言学习", icon: "character.bubble.fill", color: "#AA96DA", sortOrder: 5)
        ]
        try database.insert(objects: categories, intoTable: categoriesTable)
        print("✅ 默认分类初始化成功")
    }
    
    // MARK: - CRUD
    
    func insertWordList(_ wordList: LLDBWordList) throws -> Int64 {
        try database.insert(objects: wordList, intoTable: wordListsTable)
        // WCDB 会自动填充 id 字段
        return Int64(wordList.id ?? 0)
    }
    
    func insertWordLists(_ wordLists: [LLDBWordList]) throws {
        try database.insert(objects: wordLists, intoTable: wordListsTable)
    }
    
    func updateWordList(_ wordList: LLDBWordList, on properties: [LLDBWordList.CodingKeys]) throws {
        guard let id = wordList.id else { return }
        wordList.updatedAt = Date().timeIntervalSince1970
        try database.update(table: wordListsTable, on: properties + [.updatedAt], with: wordList, where: LLDBWordList.Properties.id == id)
    }
    
    func deleteWordList(id: Int) throws {
        try database.delete(fromTable: wordListsTable, where: LLDBWordList.Properties.id == id)
    }
    
    func getAllWordLists() throws -> [LLDBWordList] {
        return try database.getObjects(on: LLDBWordList.Properties.all, fromTable: wordListsTable)
    }
    
    func getWordListsSortedByLastStudied() throws -> [LLDBWordList] {
        return try database.getObjects(
            on: LLDBWordList.Properties.all,
            fromTable: wordListsTable,
            orderBy: [
                LLDBWordList.Properties.isFavorite.asOrder(by: .descending),
                LLDBWordList.Properties.createdAt.asOrder(by: .descending)
            ]
        )
    }
    
    func getWordList(id: Int) throws -> LLDBWordList? {
        return try database.getObject(on: LLDBWordList.Properties.all, fromTable: wordListsTable, where: LLDBWordList.Properties.id == id)
    }
    
    func getWordListByCategoryId(_ categoryId: Int) throws -> [LLDBWordList] {
        return try database.getObjects(
            on: LLDBWordList.Properties.all,
            fromTable: wordListsTable,
            where: LLDBWordList.Properties.categoryId == categoryId,
            orderBy: [LLDBWordList.Properties.createdAt.asOrder(by: .descending)]
        )
    }
    
    func updateWordListStats(id: Int, totalWords: Int? = nil, learnedWords: Int? = nil) throws {
        guard let wordList = try getWordList(id: id) else { return }
        if let total = totalWords { wordList.totalWords = total }
        if let learned = learnedWords {
            wordList.learnedWords = learned
        }
        try updateWordList(wordList, on: [.totalWords, .learnedWords])
    }
    
    func toggleWordListFavorite(id: Int) throws {
        guard let wordList = try getWordList(id: id) else { return }
        wordList.isFavorite = !wordList.isFavorite
        try updateWordList(wordList, on: [.isFavorite])
    }
    
    // MARK: - 分类管理
    
    func getAllCategories() throws -> [LLDBWordListCategory] {
        return try database.getObjects(
            on: LLDBWordListCategory.Properties.all,
            fromTable: categoriesTable,
            orderBy: [LLDBWordListCategory.Properties.sortOrder.asOrder(by: .ascending)]
        )
    }
    
    func getCategoryById(_ id: Int) throws -> LLDBWordListCategory? {
        return try database.getObject(
            on: LLDBWordListCategory.Properties.all,
            fromTable: categoriesTable,
            where: LLDBWordListCategory.Properties.id == id
        )
    }
    
    // MARK: - 单词管理
    
    /// 批量插入单词
    func insertWords(_ words: [LLDBWord]) throws {
        try database.insert(objects: words, intoTable: wordsTable)
    }
    
    /// 获取词库的所有单词
    func getWords(forWordListId wordListId: Int) throws -> [LLDBWord] {
        return try database.getObjects(
            on: LLDBWord.Properties.all,
            fromTable: wordsTable,
            where: LLDBWord.Properties.wordListId == wordListId,
            orderBy: [LLDBWord.Properties.id.asOrder(by: .ascending)]
        )
    }
    
    /// 获取词库的单词数量
    func getWordCount(forWordListId wordListId: Int) throws -> Int {
        let count = try database.getValue(
            on: LLDBWord.Properties.id.count(),
            fromTable: wordsTable,
            where: LLDBWord.Properties.wordListId == wordListId
        ).int32Value
        return Int(count)
    }
    
    /// 获取词库的已学习单词数量
    func getLearnedWordCount(forWordListId wordListId: Int) throws -> Int {
        let count = try database.getValue(
            on: LLDBWord.Properties.id.count(),
            fromTable: wordsTable,
            where: LLDBWord.Properties.wordListId == wordListId && LLDBWord.Properties.isLearned == true
        ).int32Value
        return Int(count)
    }
    
    /// 更新单词学习状态
    func updateWordLearningStatus(wordId: Int, isLearned: Bool) throws {
        // 先获取单词
        guard let word = try database.getObject(
            on: LLDBWord.Properties.all,
            fromTable: wordsTable,
            where: LLDBWord.Properties.id == wordId
        ) as LLDBWord? else {
            return
        }
        
        // 更新状态
        word.isLearned = isLearned
        word.lastReviewedAt = Date().timeIntervalSince1970
        
        // 写回数据库
        try database.update(
            table: wordsTable,
            on: [LLDBWord.Properties.isLearned, LLDBWord.Properties.lastReviewedAt],
            with: word,
            where: LLDBWord.Properties.id == wordId
        )
    }
    
    /// 删除词库的所有单词
    func deleteWords(forWordListId wordListId: Int) throws {
        try database.delete(
            fromTable: wordsTable,
            where: LLDBWord.Properties.wordListId == wordListId
        )
    }
    
    /// 搜索单词
    func searchWords(keyword: String, wordListId: Int? = nil) throws -> [LLDBWord] {
        var condition = LLDBWord.Properties.word.like("%\(keyword)%") || LLDBWord.Properties.translation.like("%\(keyword)%")
        
        if let listId = wordListId {
            condition = condition && LLDBWord.Properties.wordListId == listId
        }
        
        return try database.getObjects(
            on: LLDBWord.Properties.all,
            fromTable: wordsTable,
            where: condition,
            limit: 100
        )
    }
}
