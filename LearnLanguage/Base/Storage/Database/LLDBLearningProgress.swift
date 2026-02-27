//
//  LLDBLearningProgress.swift
//  LearnLanguage
//
//  学习进度记录表模型（WCDB）
//

import Foundation
import WCDBSwift

/// 学习进度记录表模型
final class LLDBLearningProgress: TableCodable {
    
    var id: Int? = nil                      // 自增ID
    var wordId: String = ""                 // 单词ID
    var wordListId: String = ""             // 词库ID
    
    // 学习状态
    var status: Int = 0                     // 学习状态：0=未学习, 1=学习中, 2=已掌握
    var lastFeedback: String = ""           // 最后一次反馈：know/unclear/unknown
    
    // 学习统计
    var learnCount: Int = 0                 // 学习次数
    var correctCount: Int = 0               // 标记为"认识"的次数
    var unclearCount: Int = 0               // 标记为"模糊"的次数
    var wrongCount: Int = 0                 // 标记为"不认识"的次数
    
    // 时间记录
    var firstSeenAt: TimeInterval = 0       // 首次学习时间
    var lastSeenAt: TimeInterval = 0        // 最后学习时间
    
    // 打字练习相关
    var typingPracticeCount: Int = 0        // 打字练习次数
    var lastTypingAt: TimeInterval? = nil   // 最后打字练习时间
    
    // 时间字段
    var createdAt: TimeInterval = 0         // 创建时间
    var updatedAt: TimeInterval = 0         // 更新时间
    
    // WCDB 必需的属性
    enum CodingKeys: String, CodingTableKey {
        typealias Root = LLDBLearningProgress
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        // 自定义表名
        static var tableName: String {
            return "learning_progress"
        }
        
        case id
        case wordId = "word_id"
        case wordListId = "word_list_id"
        case status
        case lastFeedback = "last_feedback"
        case learnCount = "learn_count"
        case correctCount = "correct_count"
        case unclearCount = "unclear_count"
        case wrongCount = "wrong_count"
        case firstSeenAt = "first_seen_at"
        case lastSeenAt = "last_seen_at"
        case typingPracticeCount = "typing_practice_count"
        case lastTypingAt = "last_typing_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        
        // 配置主键和索引
        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .id: ColumnConstraintBinding(isPrimary: true, isAutoIncrement: true)
            ]
        }
        
        // 配置索引
        static var indexBindings: [IndexBinding.Subfix: IndexBinding]? {
            return [
                "_word_list": IndexBinding(indexesBy: wordId, wordListId),  // 联合索引：快速查询某个词库的某个单词
                "_list": IndexBinding(indexesBy: wordListId),                // 单独索引：查询某个词库的所有学习记录
                "_status": IndexBinding(indexesBy: status),                  // 按学习状态筛选
                "_last_seen": IndexBinding(indexesBy: lastSeenAt)            // 按最后学习时间排序
            ]
        }
        
        // 配置唯一约束（同一个词库的同一个单词只能有一条记录）
        static var tableConstraintBindings: [TableConstraintBinding.Name: TableConstraintBinding]? {
            return [
                "unique_word_list": MultiUniqueBinding(indexesBy: wordId, wordListId)
            ]
        }
    }
    
    // 便利初始化方法
    init(wordId: String,
         wordListId: String,
         feedback: String) {
        
        let now = Date().timeIntervalSince1970
        self.wordId = wordId
        self.wordListId = wordListId
        self.lastFeedback = feedback
        self.learnCount = 1
        
        // 根据反馈设置状态和计数
        switch feedback {
        case "know":
            self.status = 2  // 已掌握
            self.correctCount = 1
        case "unclear":
            self.status = 1  // 学习中
            self.unclearCount = 1
        case "unknown":
            self.status = 1  // 学习中
            self.wrongCount = 1
        default:
            self.status = 0
        }
        
        self.firstSeenAt = now
        self.lastSeenAt = now
        self.createdAt = now
        self.updatedAt = now
    }
}

