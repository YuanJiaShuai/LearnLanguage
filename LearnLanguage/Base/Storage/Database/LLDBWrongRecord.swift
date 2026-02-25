//
//  LLDBWrongRecord.swift
//  LearnLanguage
//
//  错题记录表模型（WCDB）
//

import Foundation
import WCDBSwift

/// 错题记录表模型
final class LLDBWrongRecord: TableCodable {
    
    var id: Int? = nil                      // 自增ID
    var wordId: String = ""                 // 单词ID
    var listId: String = ""                 // 词库ID
    var word: String = ""                   // 单词文本（冗余字段，方便查询显示）
    var meaning: String = ""                // 释义（冗余字段，方便查询显示）
    
    // 错误统计
    var errorCount: Int = 0                 // 累计错误次数
    var firstErrorAt: TimeInterval = 0      // 首次错误时间
    var lastErrorAt: TimeInterval = 0       // 最后错误时间
    
    // 复习状态
    var isReviewed: Bool = false            // 是否已复习
    var reviewedAt: TimeInterval? = nil     // 复习时间
    var reviewCount: Int = 0                // 复习次数
    
    // 时间字段
    var createdAt: TimeInterval = 0         // 创建时间
    var updatedAt: TimeInterval = 0         // 更新时间
    
    // WCDB 必需的属性
    enum CodingKeys: String, CodingTableKey {
        typealias Root = LLDBWrongRecord
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        
        // 自定义表名为小写
        static var tableName: String {
            return "wrong_records"
        }
        
        case id
        case wordId = "word_id"
        case listId = "list_id"
        case word
        case meaning
        case errorCount = "error_count"
        case firstErrorAt = "first_error_at"
        case lastErrorAt = "last_error_at"
        case isReviewed = "is_reviewed"
        case reviewedAt = "reviewed_at"
        case reviewCount = "review_count"
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
                "_word_list": IndexBinding(indexesBy: wordId, listId),  // 联合索引：快速查询某个词库的某个单词
                "_list": IndexBinding(indexesBy: listId),                // 单独索引：查询某个词库的所有错题
                "_error_count": IndexBinding(indexesBy: errorCount),     // 按错误次数排序
                "_last_error": IndexBinding(indexesBy: lastErrorAt),     // 按最后错误时间排序
                "_reviewed": IndexBinding(indexesBy: isReviewed)         // 筛选未复习的错题
            ]
        }
        
        // 配置唯一约束（同一个词库的同一个单词只能有一条记录）
        static var tableConstraintBindings: [TableConstraintBinding.Name: TableConstraintBinding]? {
            return [
                "unique_word_list": MultiUniqueBinding(indexesBy: wordId, listId)
            ]
        }
    }
    
    // 便利初始化方法
    init(wordId: String,
         listId: String,
         word: String,
         meaning: String,
         errorCount: Int = 1) {
        
        let now = Date().timeIntervalSince1970
        self.wordId = wordId
        self.listId = listId
        self.word = word
        self.meaning = meaning
        self.errorCount = errorCount
        self.firstErrorAt = now
        self.lastErrorAt = now
        self.createdAt = now
        self.updatedAt = now
    }
}

