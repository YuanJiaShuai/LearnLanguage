//
//  LLWordFeedback.swift
//  LearnLanguage
//

import Foundation

/// 用户对当前单词的掌握反馈，供界面或学习逻辑使用
enum LLWordFeedback: String, Codable {
    case know = "认识"
    case unclear = "模糊"
    case unknown = "不认识"
}