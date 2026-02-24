//
//  LLLearningStore.swift
//  LearnLanguage
//

import Foundation
import AppKit

/// 学习进度与反馈存储；决定下一个要展示的词
final class LLLearningStore {
    static let shared = LLLearningStore()
    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var records: [String: LLLearningRecord] = [:] // key: "listId_wordId"
    private let fileName = "learning_records.json"

    private var appSupportURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("LearnLanguage", isDirectory: true)
    }

    private var fileURL: URL { appSupportURL.appendingPathComponent(fileName) }

    private init() {
        _ = try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        load()
    }

    private func key(listId: String, wordId: String) -> String { "\(listId)_\(wordId)" }

    private func load() {
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else { return }
        struct Wrapper: Codable { let records: [LLLearningRecord] }
        if let w = try? decoder.decode(Wrapper.self, from: data) {
            records = Dictionary(uniqueKeysWithValues: w.records.map { (key(listId: $0.listId, wordId: $0.wordId), $0) })
        }
    }

    private func save() {
        let list = Array(records.values)
        struct Wrapper: Codable { let records: [LLLearningRecord] }
        guard let data = try? encoder.encode(Wrapper(records: list)) else { return }
        try? data.write(to: fileURL)
    }

    func recordFeedback(wordId: String, listId: String, feedback: LLWordFeedback) {
        let k = key(listId: listId, wordId: wordId)
        records[k] = LLLearningRecord(wordId: wordId, listId: listId, feedback: feedback)
        save()
    }

    func record(forWordId wordId: String, listId: String) -> LLLearningRecord? {
        records[key(listId: listId, wordId: wordId)]
    }

    func allRecords() -> [LLLearningRecord] { Array(records.values) }

    /// 给定词库，返回下一个应展示的词（未学优先，再按反馈与时间）
    func nextWord(in list: WordList) -> LLWordEntry? {
        let learnedIds = Set(records.values.filter { $0.listId == list.id }.map { $0.wordId })
        let needReview = list.entries.filter { learnedIds.contains($0.id) }
        let notLearned = list.entries.filter { !learnedIds.contains($0.id) }
        if let next = notLearned.first { return next }
        return needReview.first
    }

    /// 今日已学习数量（按 listId 可选）
    func todayCount(listId: String? = nil) -> Int {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return records.values.filter { r in
            (listId == nil || r.listId == listId) && cal.isDate(r.lastSeenAt, inSameDayAs: today)
        }.count
    }

    /// 掌握分布：认识 / 模糊 / 不认识 数量
    func feedbackCounts(listId: String? = nil) -> (know: Int, unclear: Int, unknown: Int) {
        let list: [LLLearningRecord] = listId == nil ? Array(records.values) : records.values.filter { $0.listId == listId }
        var k = 0, u = 0, un = 0
        for r in list {
            switch r.feedback {
            case .know: k += 1
            case .unclear: u += 1
            case .unknown: un += 1
            }
        }
        return (k, u, un)
    }

    /// 总学习天数（有记录的不重复日期数）
    func totalLearningDays(listId: String? = nil) -> Int {
        let cal = Calendar.current
        let dates = Set(records.values
            .filter { listId == nil || $0.listId == listId }
            .map { cal.startOfDay(for: $0.lastSeenAt) })
        return dates.count
    }
}
