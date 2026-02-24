//
//  LLLearningRecord.swift
//  LearnLanguage
//

import Foundation
import AppKit

/// 单条学习记录（某词在某词库下的反馈与复习）
struct LLLearningRecord: Codable {
    var wordId: String
    var listId: String
    var feedback: LLWordFeedback
    var lastSeenAt: Date
    var nextReviewAt: Date?

    init(wordId: String, listId: String, feedback: LLWordFeedback, lastSeenAt: Date = Date(), nextReviewAt: Date? = nil) {
        self.wordId = wordId
        self.listId = listId
        self.feedback = feedback
        self.lastSeenAt = lastSeenAt
        self.nextReviewAt = nextReviewAt
    }
}
