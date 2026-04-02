//
//  LLDailyLearningManager.swift
//  LearnLanguage
//
//  每日学习任务管理器
//  负责管理今日复习队列和新词队列，统一为状态栏和打字浮窗提供词汇
//

import Foundation
import WCDBSwift

final class LLDailyLearningManager {
    
    static let shared = LLDailyLearningManager()
    
    // MARK: - Properties
    
    /// 今日复习队列（内存，按优先级排序）
    private var reviewQueue: [LLWordEntry] = []
    
    /// 今日新词队列（内存，按词库原始顺序）
    private var newWordQueue: [LLWordEntry] = []
    
    /// 今日新学队列（内存，按词库原始顺序）
    private var newLearnWordQueue: [LLWordEntry] = []
    
    /// 当前词库 ID
    private var currentListId: String?
    
    /// 当前词库
    private var currentWordList: WordList?
    
    /// 今日是否已初始化
    private var isInitialized = false
    
    // MARK: - Init
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 初始化/刷新今日学习队列（切换词库或 App 启动时调用）
    func setup(listId: String) {
        // 如果词库没变，不重复初始化
        if isInitialized && currentListId == listId {
            return
        }
        
        currentListId = listId
        reload()
    }
    
    /// 强制重新加载今日队列（比如从后台切换回来）
    func reload() {
        guard let listId = currentListId,
              let wordList = LLWordListStorage.shared.list(byId: listId) else {
            reviewQueue = []
            newWordQueue = []
            newLearnWordQueue = []
            isInitialized = false
            return
        }
        
        currentWordList = wordList
        loadReviewQueue()
        loadNewWordQueue(wordList: wordList, listId: listId)
        loadNewLearnWordQueue(wordList: wordList, listId: listId)
        isInitialized = true
        
        LLLogger.info("📚 今日学习队列初始化完成：复习 \(reviewQueue.count) 个，新词 \(newWordQueue.count) 个，当日已学 \(newLearnWordQueue.count) 个")
    }
    
    /// 获取下一个需要学习的词汇
    /// 优先级：历史复习词（createTime 不是今天）> 今日新词
    func nextWord() -> LLWordEntry? {
        // 先返回历史复习词
        if let first = reviewQueue.first {
            return first
        }
        
        // 历史复习词全部完成，再返回今日新词
        if let first = newWordQueue.first {
            return first
        }
        
        if let first = newLearnWordQueue.first {
            return first
        }
        
        return nil
    }
    
    /// 记录状态栏反馈并更新队列
    func recordFeedback(_ feedback: LLWordFeedback, for entry: LLWordEntry) {
        let isFromReviewQueue = reviewQueue.first?.id == entry.id
        let isFromNewQueue = newWordQueue.first?.id == entry.id
        let isFromNewLearnQueue = newLearnWordQueue.first?.id == entry.id
        
        // 从当前队列头部移除
        if isFromReviewQueue {
            reviewQueue.removeFirst()
        } else if isFromNewQueue {
            newWordQueue.removeFirst()
        } else if isFromNewLearnQueue {
            newLearnWordQueue.removeFirst()
        }
        
        // 根据反馈处理
        switch feedback {
        case .know:
            // 认识：SM-2 正常处理
            updateProgress(
                entry: entry,
                feedback: feedback,
                keepToday: false
            ) { [weak self] (wordEntry, reviewCount) in
                guard let self = self else { return }
                if reviewCount < 4 {
                    if isFromReviewQueue {
                        self.reviewQueue.append(wordEntry)
                    } else {
                        self.newLearnWordQueue.append(wordEntry)
                    }
                } else {
                    NotificationCenter.default.post(name: .wrongWordsCountChanged, object: nil)
                }
            }
            
        case .unclear:
            updateProgress(entry: entry, feedback: feedback, keepToday: true)
            if isFromReviewQueue {
                // 历史复习词标记模糊：留在复习队列尾部继续循环
                reviewQueue.append(entry)
            } else if isFromNewLearnQueue {
                // 今日新学未达标词标记模糊：留在今日新学队列尾部继续循环
                newLearnWordQueue.append(entry)
            }
            // 今日新词标记模糊：不加入复习队列，继续学下一个新词
            
        case .unknown:
            updateProgress(entry: entry, feedback: feedback, keepToday: true)
            if isFromReviewQueue {
                // 历史复习词标记不认识：留在复习队列尾部继续循环
                reviewQueue.append(entry)
            } else if isFromNewLearnQueue {
                // 今日新学未达标词标记不认识：留在今日新学队列尾部继续循环
                newLearnWordQueue.append(entry)
            }
            // 今日新词标记不认识：不加入复习队列，继续学下一个新词
        }
        
        let source: String = {
            if isFromReviewQueue { return "复习词" }
            if isFromNewQueue { return "新词" }
            if isFromNewLearnQueue { return "今日新学词" }
            return "未知来源"
        }()
        
        LLLogger.info("📝 反馈记录：\(entry.text) -> \(feedback.rawValue)，来源：\(source)，wordId: \(entry.id), 复习队列剩余：\(reviewQueue.count)，新词队列剩余：\(newWordQueue.count)，今日新学队列剩余：\(newLearnWordQueue.count)")
    }
    
    /// 记录打字练习结果（根据错误次数映射为反馈）
    func recordTypingResult(entry: LLWordEntry, errorCount: Int) {
        let feedback: LLWordFeedback
        switch errorCount {
        case 0:       feedback = .know     // 第1次就正确 → 认识
        case 1:       feedback = .unclear  // 错1次后正确 → 模糊
        default:      feedback = .unknown  // 错2次及以上 → 不认识
        }
        
        recordFeedback(feedback, for: entry)
        
        // 同时记录打字练习次数
        guard let listId = currentListId else { return }
        do {
            try LLDatabaseManager.shared.recordTypingPractice(
                wordId: entry.id,
                wordListId: listId
            )
        } catch {
            LLLogger.error("❌ 记录打字练习失败：\(error)")
        }
    }
    
    /// 复习当日：将今天学过的词加入今日新学队列
    func restartTodayReview() {
        guard let listId = currentListId,
              let wordList = currentWordList else { return }
        
        do {
            let progressList = try LLDatabaseManager.shared.getTodayLearnedProgress(wordListId: listId)
            let words = progressList.compactMap { progress -> LLWordEntry? in
                guard let wordId = progress.wordId else { return nil }
                return wordList.entries.first(where: { $0.id == wordId })
            }
            
            reviewQueue = []
            newWordQueue = []
            newLearnWordQueue = words
            
            LLLogger.info("🔁 复习当日：已载入 \(newLearnWordQueue.count) 个词")
        } catch {
            LLLogger.error("❌ 复习当日加载失败：\(error)")
        }
    }
    
    /// 再学一组：追加一组今日新词到新词队列
    func learnAnotherBatch() {
        guard let listId = currentListId,
              let wordList = currentWordList else { return }
        
        let limit = LLSettingsStore.shared.settings.newWordsPerDay
        do {
            let candidates = try LLDatabaseManager.shared.getTodayNewWords(
                wordListId: listId,
                wordList: wordList,
                limit: limit
            )
            
            let existingIds = Set(reviewQueue.map(\.id) + newWordQueue.map(\.id) + newLearnWordQueue.map(\.id))
            let newBatch = candidates.filter { !existingIds.contains($0.id) }
            newWordQueue.append(contentsOf: newBatch)
            
            LLLogger.info("➕ 再学一组：新增 \(newBatch.count) 个词")
        } catch {
            LLLogger.error("❌ 再学一组加载失败：\(error)")
        }
    }
    
    /// 今日复习队列剩余数量
    var reviewQueueCount: Int { reviewQueue.count }
    
    /// 今日新词队列剩余数量
    var newWordQueueCount: Int { newWordQueue.count }
    
    /// 今日新学未达标队列剩余数量
    var newLearnWordQueueCount: Int { newLearnWordQueue.count }
    
    /// 今日是否还有学习任务
    var hasPendingTasks: Bool { !reviewQueue.isEmpty || !newWordQueue.isEmpty || !newLearnWordQueue.isEmpty }
    
    // MARK: - Private Methods
    
    /// 从数据库加载今日复习队列
    private func loadReviewQueue() {
        do {
            let reviewProgress = try LLDatabaseManager.shared.getTodayReviewWords()
            reviewQueue = reviewProgress.compactMap { progress -> LLWordEntry? in
                guard let wordId = progress.wordId,
                      let listId = progress.wordListId,
                      let wordList = LLWordListStorage.shared.list(byId: listId) else { return nil }
                let emtrys = wordList.entries.first(where: { $0.id == wordId })
                return emtrys
            }
        } catch {
            LLLogger.error("❌ 加载今日复习队列失败：\(error)")
            reviewQueue = []
        }
    }
    
    /// 从数据库加载今日新词队列
    private func loadNewWordQueue(wordList: WordList, listId: String) {
        let settings = LLSettingsStore.shared.settings
        let limit = settings.newWordsPerDay
        
        do {
            newWordQueue = try LLDatabaseManager.shared.getTodayNewWords(
                wordListId: listId,
                wordList: wordList,
                limit: limit
            )
        } catch {
            LLLogger.error("❌ 加载今日新词队列失败：\(error)")
            newWordQueue = []
        }
    }
    
    /// 从数据库加载今日新学未达标队列
    private func loadNewLearnWordQueue(wordList: WordList, listId: String) {
        do {
            let newLearnWordProgress = try LLDatabaseManager.shared.getTodayNewLearnWords()
            newLearnWordQueue = newLearnWordProgress.compactMap { progress -> LLWordEntry? in
                guard let wordId = progress.wordId else { return nil }
                return wordList.entries.first(where: { $0.id == wordId })
            }
        } catch {
            LLLogger.error("❌ 加载今日新词学习未达标队列失败：\(error)")
            newLearnWordQueue = []
        }
    }
    
    /// 更新数据库中的学习进度
    private func updateProgress(entry: LLWordEntry, feedback: LLWordFeedback, keepToday: Bool, onKnownWithLowReviewCount: ((LLWordEntry, Int) -> Void)? = nil) {
        do {
            let listId = entry.wordListId
            let existing = try LLDatabaseManager.shared.getLearningProgress(
                wordId: entry.id,
                wordListId: listId
            )
            
            let now = Date().timeIntervalSince1970
            
            if let record = existing {
                // 已有记录：更新
                var easeFactor = record.easeFactor ?? 2.0
                var interval = record.interval ?? 1
                
                switch feedback {
                case .know:
                    // 正常 SM-2 计算
                    interval = max(1, Int(Double(interval) * easeFactor))
                    record.correctCount = (record.correctCount ?? 0) + 1
                    record.reviewCount = (record.reviewCount ?? 0) + 1
                    
                    if record.reviewCount ?? 0 >= 4 {
                        easeFactor = min(2.0, easeFactor + 0.1)
                        interval = max(1, Int(Double(interval) * easeFactor))
                        record.nextReviewAt = now + Double(interval) * 86400
                    }
                    record.status = 2
                case .unclear:
                    // 小幅下降，今天继续
                    easeFactor = max(1.3, easeFactor - 0.1)
                    interval = max(1, interval - 1)
                    record.unclearCount = (record.unclearCount ?? 0) + 1
                    record.reviewCount = max(0, (record.reviewCount ?? 0) - 1)
                    if record.status == 2 { record.status = 1 }
                    record.nextReviewAt = now  // 今天内继续
                    
                case .unknown:
                    // 重置
                    easeFactor = 1.3
                    interval = 1
                    record.wrongCount = (record.wrongCount ?? 0) + 1
                    record.reviewCount = 0
                    record.status = 1
                    record.nextReviewAt = now  // 今天内继续
                }
                
                record.easeFactor = easeFactor
                record.interval = interval
                record.lastReviewAt = now
                record.lastFeedback = feedback.rawValue
                record.learnCount = (record.learnCount ?? 0) + 1
                record.lastSeenAt = now
                record.updatedAt = now
                
                try LLDatabaseManager.shared.database.update(
                    table: "learning_progress",
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
                        LLDBLearningProgress.Properties.learnCount,
                        LLDBLearningProgress.Properties.lastSeenAt,
                        LLDBLearningProgress.Properties.updatedAt
                    ],
                    with: record,
                    where: LLDBLearningProgress.Properties.id == (record.id ?? 0)
                )
                
                // 插入学习明细记录
                let history = LLDBLearningHistory(wordId: entry.id, wordListId: listId, feedback: feedback.rawValue, sessionType: "learn")
                try LLDatabaseManager.shared.database.insert(objects: [history], intoTable: "learning_history")
                // 发送回掉 更新侧边栏
                onKnownWithLowReviewCount?(entry, record.reviewCount ?? 0)
            } else {
                // 无记录：首次学习，插入新记录
                let newRecord = LLDBLearningProgress(
                    wordId: entry.id,
                    wordListId: listId,
                    feedback: feedback.rawValue
                )
                
                // 如果是模糊/不认识，覆盖 nextReviewAt 为今天
                if keepToday {
                    newRecord.nextReviewAt = now
                }
                
                try LLDatabaseManager.shared.database.insert(
                    objects: [newRecord],
                    intoTable: "learning_progress"
                )
                
                // 首次学习，更新词库已学数量
                try LLDatabaseManager.shared.recalculateWordListLearnedCount(wordListId: listId)
                
                // 插入学习明细记录
                let history = LLDBLearningHistory(wordId: entry.id, wordListId: listId, feedback: feedback.rawValue, sessionType: "learn")
                try LLDatabaseManager.shared.database.insert(objects: [history], intoTable: "learning_history")
            }
            
        } catch {
            LLLogger.error("❌ 更新学习进度失败：\(error)")
        }
    }
}
