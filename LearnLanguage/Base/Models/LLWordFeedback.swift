//
//  LLWordFeedback.swift
//  LearnLanguage
//

import Foundation

/// 用户对当前单词的掌握反馈，供界面或学习逻辑使用
enum LLWordFeedback: String, Codable {
    case know = "know"
    case unclear = "unclear"
    case unknown = "unknown"
    
    /// 获取本地化显示文本
    var displayName: String {
        switch self {
        case .know:
            return NSLocalizedString("Know", comment: "User knows the word")
        case .unclear:
            return NSLocalizedString("Unclear", comment: "User is unclear about the word")
        case .unknown:
            return NSLocalizedString("Unknown", comment: "User doesn't know the word")
        }
    }
}