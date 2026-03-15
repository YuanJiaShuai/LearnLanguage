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
    private let learningProgressTable = "learning_progress"
    
    private init() {
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        dbPath = documentPath + "/LearnLanguage.db"
        
        LLLogger.info("\n" + String(repeating: "=", count: 60))
        LLLogger.info("📁 数据库路径：")
        LLLogger.info("   \(dbPath)")
        LLLogger.info(String(repeating: "=", count: 60) + "\n")
        
        // 注意：不在这里打开数据库，等待 LLDatabaseInitializer 完成文件准备
        // database = Database(withPath: dbPath)
        // createTables()
    }
    
    /// 打开数据库连接（在数据库文件准备好后调用）
    func openDatabase() {
        guard database == nil else {
            LLLogger.warn("⚠️ 数据库已经打开")
            return
        }
        
        database = Database(withPath: dbPath)
        
        // 注意：不需要 createTables()，因为数据库文件已经包含了所有表和数据
        // 只在数据库文件不存在时才需要创建表
        
        // 检查并创建学习进度表（如果不存在）
        createLearningProgressTableIfNeeded()
        
        LLLogger.info("✅ 数据库连接已打开")
    }
    
    /// 检查并创建学习进度表（如果不存在）
    private func createLearningProgressTableIfNeeded() {
        do {
            // 创建学习进度表
            try database.create(table: learningProgressTable, of: LLDBLearningProgress.self)
            LLLogger.info("✅ 学习进度表检查完成")
        } catch {
            LLLogger.warn("⚠️ 学习进度表创建失败（可能已存在）：\(error)")
        }
    }
    
    private func createTables() {
        do {
            // 创建分类表
            try database.create(table: categoriesTable, of: LLDBWordListCategory.self)
            LLLogger.info("✅ 分类表创建成功")
            
            // 创建词库表
            try database.create(table: wordListsTable, of: LLDBWordList.self)
            LLLogger.info("✅ 词库表创建成功")
            
            // 创建单词表
            try database.create(table: wordsTable, of: LLDBWord.self)
            LLLogger.info("✅ 单词表创建成功")
            
            // 初始化默认分类
            try initializeDefaultCategories()
            
        } catch {
            LLLogger.error("❌ 创建表失败：\(error)")
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
        LLLogger.info("✅ 默认分类初始化成功")
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
    
    // MARK: - 错题记录管理（已迁移到 learning_progress）
    
    /// 获取复习记录（wrongCount > 0 的学习进度）
    /// 支持按时间范围筛选
    func getReviewRecords(
        wordListId: String,
        startDate: Date? = nil,
        endDate: Date? = nil
    ) throws -> [LLDBLearningProgress] {
        let calendar = Calendar.current
        
        // 构建时间条件
        var condition = LLDBLearningProgress.Properties.wordListId == wordListId
            && LLDBLearningProgress.Properties.learnCount > 0
        
        if let start = startDate {
            let startTimestamp = calendar.startOfDay(for: start).timeIntervalSince1970
            condition = condition && LLDBLearningProgress.Properties.updatedAt >= startTimestamp
        }
        
        if let end = endDate {
            let endTimestamp = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: end)!.timeIntervalSince1970
            condition = condition && LLDBLearningProgress.Properties.updatedAt <= endTimestamp
        }
        
        return try database.getObjects(
            on: LLDBLearningProgress.Properties.all,
            fromTable: learningProgressTable,
            where: condition,
            orderBy: [
                LLDBLearningProgress.Properties.learnCount.asOrder(by: .descending),
                LLDBLearningProgress.Properties.updatedAt.asOrder(by: .descending)
            ]
        )
    }
    
    /// 获取今日复习记录
    func getTodayReviewRecords(wordListId: String) throws -> [LLDBLearningProgress] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return try getReviewRecords(wordListId: wordListId, startDate: today, endDate: Date())
    }
    
    /// 获取本周复习记录
    func getWeekReviewRecords(wordListId: String) throws -> [LLDBLearningProgress] {
        let calendar = Calendar.current
        let today = Date()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        return try getReviewRecords(wordListId: wordListId, startDate: weekAgo, endDate: today)
    }
    
    /// 获取本月复习记录
    func getMonthReviewRecords(wordListId: String) throws -> [LLDBLearningProgress] {
        let calendar = Calendar.current
        let today = Date()
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: today)!
        return try getReviewRecords(wordListId: wordListId, startDate: monthAgo, endDate: today)
    }
    
    /// 获取所有复习记录
    func getAllReviewRecords(wordListId: String) throws -> [LLDBLearningProgress] {
        return try getReviewRecords(wordListId: wordListId)
    }
    
    // MARK: - 学习进度管理
    
    /// 记录学习进度（第一次学习或更新）
    func recordLearningProgress(wordId: String, wordListId: String, feedback: String) throws {
        // 查询是否已存在记录
        let existing = try database.getObject(
            on: LLDBLearningProgress.Properties.all,
            fromTable: learningProgressTable,
            where: LLDBLearningProgress.Properties.wordId == wordId && LLDBLearningProgress.Properties.wordListId == wordListId
        ) as LLDBLearningProgress?
        
        let now = Date().timeIntervalSince1970
        
        if let record = existing {
            // 已存在，更新记录
            record.learnCount = (record.learnCount ?? 0) + 1
            record.lastFeedback = feedback
            record.lastSeenAt = now
            record.updatedAt = now
            
            // 更新反馈计数
            switch feedback {
            case "know":
                record.correctCount = (record.correctCount ?? 0) + 1
                record.status = 2  // 已掌握
            case "unclear":
                record.unclearCount = (record.unclearCount ?? 0) + 1
                // 如果之前是已掌握，降级为学习中
                if record.status == 2 {
                    record.status = 1
                }
            case "unknown":
                record.wrongCount = (record.wrongCount ?? 0) + 1
                record.status = 1  // 学习中
            default:
                break
            }
            
            try database.update(
                table: learningProgressTable,
                on: [
                    LLDBLearningProgress.Properties.learnCount,
                    LLDBLearningProgress.Properties.lastFeedback,
                    LLDBLearningProgress.Properties.status,
                    LLDBLearningProgress.Properties.correctCount,
                    LLDBLearningProgress.Properties.unclearCount,
                    LLDBLearningProgress.Properties.wrongCount,
                    LLDBLearningProgress.Properties.lastSeenAt,
                    LLDBLearningProgress.Properties.updatedAt
                ],
                with: record,
                where: LLDBLearningProgress.Properties.id == record.id ?? 0
            )
            
            LLLogger.info("✅ 更新学习记录：\(wordId)，反馈：\(feedback)")
            
        } else {
            // 不存在，插入新记录
            let newRecord = LLDBLearningProgress(
                wordId: wordId,
                wordListId: wordListId,
                feedback: feedback
            )
            
            try database.insert(objects: newRecord, intoTable: learningProgressTable)
            
            // 第一次学习，更新词库的 learned_words 计数
            try updateWordListLearnedCount(wordListId: wordListId, increment: 1)
            
            LLLogger.info("✅ 新增学习记录：\(wordId)，反馈：\(feedback)")
        }
    }
    
    /// 更新词库的已学习单词数（增量更新）
    private func updateWordListLearnedCount(wordListId: String, increment: Int) throws {
        guard let listId = Int(wordListId),
              let wordList = try getWordList(id: listId) else {
            return
        }
        
        wordList.learnedWords = max(0, wordList.learnedWords + increment)
        try updateWordList(wordList, on: [.learnedWords])
    }
    
    /// 重新计算词库的已学习单词数（完整计算）
    func recalculateWordListLearnedCount(wordListId: String) throws {
        let count = try database.getValue(
            on: LLDBLearningProgress.Properties.id.count(),
            fromTable: learningProgressTable,
            where: LLDBLearningProgress.Properties.wordListId == wordListId
        ).int32Value
        
        guard let listId = Int(wordListId),
              let wordList = try getWordList(id: listId) else {
            return
        }
        
        wordList.learnedWords = Int(count)
        try updateWordList(wordList, on: [.learnedWords])
    }
    
    /// 获取某个词库的学习进度统计
    func getWordListProgressStats(wordListId: String) throws -> (total: Int, learned: Int, mastered: Int, learning: Int) {
        // 总单词数
        guard let listId = Int(wordListId) else {
            return (0, 0, 0, 0)
        }
        let total = try getWordCount(forWordListId: listId)
        
        // 已学习数（有学习记录的）
        let learned = try database.getValue(
            on: LLDBLearningProgress.Properties.id.count(),
            fromTable: learningProgressTable,
            where: LLDBLearningProgress.Properties.wordListId == wordListId
        ).int32Value
        
        // 已掌握数（status = 2）
        let mastered = try database.getValue(
            on: LLDBLearningProgress.Properties.id.count(),
            fromTable: learningProgressTable,
            where: LLDBLearningProgress.Properties.wordListId == wordListId && LLDBLearningProgress.Properties.status == 2
        ).int32Value
        
        // 学习中（status = 1）
        let learning = try database.getValue(
            on: LLDBLearningProgress.Properties.id.count(),
            fromTable: learningProgressTable,
            where: LLDBLearningProgress.Properties.wordListId == wordListId && LLDBLearningProgress.Properties.status == 1
        ).int32Value
        
        return (total, Int(learned), Int(mastered), Int(learning))
    }
    
    /// 获取某个单词的学习进度
    func getLearningProgress(wordId: String, wordListId: String) throws -> LLDBLearningProgress? {
        return try database.getObject(
            on: LLDBLearningProgress.Properties.all,
            fromTable: learningProgressTable,
            where: LLDBLearningProgress.Properties.wordId == wordId && LLDBLearningProgress.Properties.wordListId == wordListId
        )
    }
    
    /// 获取某个词库的所有学习记录
    func getAllLearningProgress(wordListId: String) throws -> [LLDBLearningProgress] {
        return try database.getObjects(
            on: LLDBLearningProgress.Properties.all,
            fromTable: learningProgressTable,
            where: LLDBLearningProgress.Properties.wordListId == wordListId,
            orderBy: [LLDBLearningProgress.Properties.lastSeenAt.asOrder(by: .descending)]
        )
    }
    
    /// 获取今日学习的单词数
    func getTodayLearnedCount(wordListId: String? = nil) throws -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayTimestamp = today.timeIntervalSince1970
        
        var condition = LLDBLearningProgress.Properties.lastSeenAt >= todayTimestamp
        if let listId = wordListId {
            condition = condition && LLDBLearningProgress.Properties.wordListId == listId
        }
        
        let count = try database.getValue(
            on: LLDBLearningProgress.Properties.id.count(),
            fromTable: learningProgressTable,
            where: condition
        ).int32Value
        
        return Int(count)
    }
    
    /// 获取下一个应展示的单词
    /// 优先级：今日到期复习词 > 新词汇 > 兜底（最早学习的词）
    func nextWord(in wordList: WordList) -> LLWordEntry? {
        do {
            let calendar = Calendar.current
            let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
            let endOfDayTimestamp = endOfDay.timeIntervalSince1970
            
            // 第一步：取今日所有到期的复习词（nextReviewAt <= 今天结束）
            let reviewProgressList = try database.getObjects(
                on: LLDBLearningProgress.Properties.all,
                fromTable: learningProgressTable,
                where: LLDBLearningProgress.Properties.wordListId == wordList.id
                    && LLDBLearningProgress.Properties.nextReviewAt <= endOfDayTimestamp,
                orderBy: [LLDBLearningProgress.Properties.nextReviewAt.asOrder(by: .ascending)]
            ) as [LLDBLearningProgress]
            
            // 优先返回最早到期的复习词
            if let firstReview = reviewProgressList.first,
               let reviewWordId = firstReview.wordId,
               let entry = wordList.entries.first(where: { $0.id == reviewWordId }) {
                LLLogger.debug("📖 复习词汇：\(entry.text)，下次复习时间已到期")
                return entry
            }
            
            // 第二步：没有复习词，取未学过的新词（按原始顺序）
            let allProgressList = try database.getObjects(
                on: [LLDBLearningProgress.Properties.wordId],
                fromTable: learningProgressTable,
                where: LLDBLearningProgress.Properties.wordListId == wordList.id
            ) as [LLDBLearningProgress]
            
            let learnedIds = Set(allProgressList.compactMap { $0.wordId })
            
            if let newWord = wordList.entries.first(where: { !learnedIds.contains($0.id) }) {
                LLLogger.debug("🆕 新词汇：\(newWord.text)")
                return newWord
            }
            
            // 第三步：兜底——所有词都学过且今日无复习任务，返回下次最早到期的词
            let nextScheduled = try database.getObjects(
                on: LLDBLearningProgress.Properties.all,
                fromTable: learningProgressTable,
                where: LLDBLearningProgress.Properties.wordListId == wordList.id,
                orderBy: [LLDBLearningProgress.Properties.nextReviewAt.asOrder(by: .ascending)],
                limit: 1
            ) as [LLDBLearningProgress]
            
            if let next = nextScheduled.first,
               let nextWordId = next.wordId,
               let entry = wordList.entries.first(where: { $0.id == nextWordId }) {
                LLLogger.debug("⏳ 兜底：返回下次最早到期的词 \(entry.text)")
                return entry
            }
            
            // 最终兜底：返回第一个
            return wordList.entries.first
            
        } catch {
            LLLogger.error("❌ nextWord 查询失败：\(error)")
            return wordList.entries.first
        }
    }
    
    // MARK: - 每日学习任务
    
    /// 获取今日需要复习的词汇（nextReviewAt <= 今天结束时间戳，全部取出）
    func getTodayReviewWords(wordListId: String) throws -> [LLDBLearningProgress] {
        let calendar = Calendar.current
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: Date())!
        let endOfDayTimestamp = endOfDay.timeIntervalSince1970
        
        return try database.getObjects(
            on: LLDBLearningProgress.Properties.all,
            fromTable: learningProgressTable,
            where: LLDBLearningProgress.Properties.wordListId == wordListId
                && LLDBLearningProgress.Properties.nextReviewAt <= endOfDayTimestamp,
            orderBy: [LLDBLearningProgress.Properties.nextReviewAt.asOrder(by: .ascending)]
        )
    }
    
    /// 获取今日需要学习的新词汇（在 learning_progress 中没有记录的词，按原始顺序取 limit 个）
    func getTodayNewWords(wordListId: String, wordList: WordList, limit: Int) throws -> [LLWordEntry] {
        // 取出该词库所有已有学习记录的 wordId
        let progressList = try database.getObjects(
            on: [LLDBLearningProgress.Properties.wordId],
            fromTable: learningProgressTable,
            where: LLDBLearningProgress.Properties.wordListId == wordListId
        ) as [LLDBLearningProgress]
        
        let learnedIds = Set(progressList.compactMap { $0.wordId })
        
        // 从词库中过滤出未学习的词，按原始顺序取 limit 个
        let newWords = wordList.entries
            .filter { !learnedIds.contains($0.id) }
            .prefix(limit)
        
        return Array(newWords)
    }
    
    /// 更新复习结果（根据 SM-2 算法更新 nextReviewAt、interval、easeFactor）
    func updateReviewResult(wordId: String, wordListId: String, feedback: String) throws {
        guard let record = try getLearningProgress(wordId: wordId, wordListId: wordListId) else { return }
        
        let now = Date().timeIntervalSince1970
        var easeFactor = record.easeFactor ?? 2.5
        var interval = record.interval ?? 1
        
        switch feedback {
        case "know":
            // 答对：延长间隔
            easeFactor = min(3.0, easeFactor + 0.1)
            interval = max(1, Int(Double(interval) * easeFactor))
            record.correctCount = (record.correctCount ?? 0) + 1
            record.status = 2  // 已掌握
        case "unclear":
            // 模糊：保持间隔，稍微降低系数
            easeFactor = max(1.3, easeFactor - 0.1)
            interval = max(1, interval - 1)
            record.unclearCount = (record.unclearCount ?? 0) + 1
            if record.status == 2 { record.status = 1 }
        case "unknown":
            // 忘记：根据连续失败次数决定重置程度
            record.wrongCount = (record.wrongCount ?? 0) + 1
            let consecutiveWrong = record.wrongCount ?? 1
            if consecutiveWrong >= 2 {
                // 连续失败 2 次以上：完全重置
                easeFactor = 1.3
                interval = 1
            } else {
                // 首次失败：部分回退
                easeFactor = max(1.3, easeFactor - 0.2)
                interval = max(1, interval - 1)
            }
            record.status = 1  // 学习中
        default:
            break
        }
        
        record.easeFactor = easeFactor
        record.interval = interval
        record.nextReviewAt = now + Double(interval) * 86400
        record.lastReviewAt = now
        record.lastFeedback = feedback
        record.reviewCount = (record.reviewCount ?? 0) + 1
        record.lastSeenAt = now
        record.updatedAt = now
        
        try database.update(
            table: learningProgressTable,
            on: [
                LLDBLearningProgress.Properties.easeFactor,
                LLDBLearningProgress.Properties.interval,
                LLDBLearningProgress.Properties.nextReviewAt,
                LLDBLearningProgress.Properties.lastReviewAt,
                LLDBLearningProgress.Properties.lastFeedback,
                LLDBLearningProgress.Properties.reviewCount,
                LLDBLearningProgress.Properties.status,
                LLDBLearningProgress.Properties.correctCount,
                LLDBLearningProgress.Properties.unclearCount,
                LLDBLearningProgress.Properties.wrongCount,
                LLDBLearningProgress.Properties.lastSeenAt,
                LLDBLearningProgress.Properties.updatedAt
            ],
            with: record,
            where: LLDBLearningProgress.Properties.id == record.id ?? 0
        )
        
        LLLogger.info("✅ 更新复习结果：\(wordId)，反馈：\(feedback)，下次复习间隔：\(interval)天")
    }
    
    /// 删除某个词库的所有学习记录
    func deleteLearningProgress(wordListId: String) throws {
        try database.delete(
            fromTable: learningProgressTable,
            where: LLDBLearningProgress.Properties.wordListId == wordListId
        )
    }
    
    /// 记录打字练习
    func recordTypingPractice(wordId: String, wordListId: String) throws {
        guard let record = try getLearningProgress(wordId: wordId, wordListId: wordListId) else {
            return
        }
        
        let now = Date().timeIntervalSince1970
        record.typingPracticeCount = (record.typingPracticeCount ?? 0) + 1
        record.lastTypingAt = now
        record.updatedAt = now
        
        try database.update(
            table: learningProgressTable,
            on: [
                LLDBLearningProgress.Properties.typingPracticeCount,
                LLDBLearningProgress.Properties.lastTypingAt,
                LLDBLearningProgress.Properties.updatedAt
            ],
            with: record,
            where: LLDBLearningProgress.Properties.id == record.id ?? 0
        )
    }
}
