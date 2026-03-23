//
//  LLWordService.swift
//  LearnLanguage
//
//  从系统词典获取音标（离线，基于 TranslateP/WordService）
//

import Foundation
import CoreServices

struct LLWordService {

    /// 从系统词典获取单词音标
    /// - Parameter word: 要查询的单词
    /// - Returns: 音标字符串，如 "[həˈloʊ]"，查不到返回 nil
    static func getPhonetics(for word: String) -> String? {
        let range = CFRangeMake(0, word.count)

        guard let unmanagedDefinition = DCSCopyTextDefinition(nil, word as CFString, range) else {
            return nil
        }

        let definition = unmanagedDefinition.takeRetainedValue() as String

        // 词典返回格式：单词 | 音标 | 释义 | ...
        let components = definition.components(separatedBy: "|")

        guard components.count >= 2 else { return nil }

        let phonetics = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        return phonetics.isEmpty ? nil : "[" + phonetics + "]"
    }
}
