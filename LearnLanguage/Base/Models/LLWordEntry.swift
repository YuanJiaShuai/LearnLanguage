//
//  LLWordEntry.swift
//  LearnLanguage
//

import Foundation

/// 单条学习项（单词/短语）
struct LLWordEntry: Codable, Identifiable, Equatable {
    var id: String
    var wordListId: String
    var text: String           // 原文，如 "apple"
    var meaning: String        // 释义
    var phonetic: String?     // 音标，如 "/ˈæpl/"
    var language: LLLearningLanguage

    init(id: String = UUID().uuidString, wordListId: String, text: String, meaning: String, phonetic: String? = nil, language: LLLearningLanguage) {
        self.id = id
        self.wordListId = wordListId
        self.text = text
        self.meaning = meaning
        self.phonetic = phonetic
        self.language = language
    }
}

/// 词库（兼容 qwerty-learner 等：name/trans/usphone/ukphone）
struct WordList: Codable, Identifiable {
    var id: String
    var name: String
    var category: String
    var language: LLLearningLanguage
    var entries: [LLWordEntry]
    var createdAt: Date
    var totalWords: Int? // 实际单词数量（用于列表页显示，避免加载所有单词）
    var isVocabularyNotebook: Bool = false

    init(id: String = UUID().uuidString, name: String, category: String = "未分类", language: LLLearningLanguage, entries: [LLWordEntry] = [], createdAt: Date = Date(), totalWords: Int? = nil, isVocabularyNotebook: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.language = language
        self.entries = entries
        self.createdAt = createdAt
        self.totalWords = totalWords
        self.isVocabularyNotebook = isVocabularyNotebook
    }

    var entryCount: Int { 
        // 优先使用 totalWords，如果没有则使用 entries.count
        totalWords ?? entries.count 
    }

    enum CodingKeys: String, CodingKey { case id, name, category, language, entries, createdAt, totalWords, isVocabularyNotebook }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        category = try c.decodeIfPresent(String.self, forKey: .category) ?? "未分类"
        language = try c.decode(LLLearningLanguage.self, forKey: .language)
        entries = try c.decode([LLWordEntry].self, forKey: .entries)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        totalWords = try c.decodeIfPresent(Int.self, forKey: .totalWords)
        isVocabularyNotebook = try c.decodeIfPresent(Bool.self, forKey: .isVocabularyNotebook) ?? false
    }
}
