//
//  LLTranslationManager.swift
//  LearnLanguage
//
//  翻译管理器 - 封装系统 Translation API（需要 macOS 15.0+）
//

import Foundation

final class LLTranslationManager {

    static let shared = LLTranslationManager()

    private init() {}

    // MARK: - Types

    struct TranslationResult {
        let originalText: String
        let translatedText: String
        let phonetics: String?
    }

    enum TranslationError: Error, LocalizedError {
        case emptyInput
        case unsupportedSystem
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .emptyInput:          return "请输入要翻译的内容"
            case .unsupportedSystem:   return "翻译功能需要 macOS 15.0 或更高版本"
            case .failed(let msg):     return "翻译失败：\(msg)"
            }
        }
    }

    enum Direction {
        case enToZh   // 英文 → 中文
        case zhToEn   // 中文 → 英文
        case jaToEn   // 日文 → 英文
        case koToEn   // 韩文 → 英文

        var sourceIdentifier: String {
            switch self {
            case .enToZh: return "en"
            case .zhToEn: return "zh"
            case .jaToEn: return "ja"
            case .koToEn: return "ko"
            }
        }

        var targetIdentifier: String {
            switch self {
            case .enToZh: return "zh"
            case .zhToEn, .jaToEn, .koToEn: return "en"
            }
        }
    }

    // MARK: - Public

    /// 翻译文字
    /// - Parameters:
    ///   - text: 原文
    ///   - direction: 翻译方向，默认英文 -> 中文
    ///   - completion: 主线程回调
    func translate(
        _ text: String,
        direction: Direction = .enToZh,
        completion: @escaping (Result<TranslationResult, Error>) -> Void
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion(.failure(TranslationError.emptyInput))
            return
        }

        guard #available(macOS 15.0, *) else {
            completion(.failure(TranslationError.unsupportedSystem))
            return
        }

        // 只有英文 → 中文时才获取音标（离线，基于系统词典）
        let phonetics: String? = direction == .enToZh ? LLWordService.getPhonetics(for: trimmed) : nil

        let source = Locale.Language(identifier: direction.sourceIdentifier)
        let target = Locale.Language(identifier: direction.targetIdentifier)

        LLTranslationTaskBridge.shared.performTranslation(trimmed, source: source, target: target) { result in
            switch result {
            case .success(let translated):
                let r = TranslationResult(originalText: trimmed, translatedText: translated, phonetics: phonetics)
                completion(.success(r))
            case .failure(let error):
                completion(.failure(TranslationError.failed(error.localizedDescription)))
            }
        }
    }
}
