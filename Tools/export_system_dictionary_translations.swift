import Foundation
import CoreServices

private struct WordRow: Codable {
    let id: Int
    let wordListId: Int
    let word: String
    let currentTranslation: String
}

private struct TranslationCandidate: Codable {
    let id: Int
    let wordListId: Int
    let word: String
    let currentTranslation: String
    let newTranslation: String?
    let groups: [DefinitionGroup]
    let status: String
}

private struct DefinitionGroup: Codable {
    let partOfSpeech: String
    let definitions: [String]
}

@main
private enum DictionaryTranslationExporter {
    static func main() {
        let input = FileHandle.standardInput.readDataToEndOfFile()
        let rows = (try? JSONDecoder().decode([WordRow].self, from: input)) ?? []
        let exporter = SystemDictionaryTranslationParser()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]

        var cache: [String: (String?, [DefinitionGroup], String)] = [:]

        for (index, row) in rows.enumerated() {
            let key = row.word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let parsed: (String?, [DefinitionGroup], String)
            if let cached = cache[key] {
                parsed = cached
            } else {
                parsed = exporter.translation(for: row.word)
                cache[key] = parsed
            }

            let candidate = TranslationCandidate(
                id: row.id,
                wordListId: row.wordListId,
                word: row.word,
                currentTranslation: row.currentTranslation,
                newTranslation: parsed.0,
                groups: parsed.1,
                status: parsed.2
            )

            if let data = try? encoder.encode(candidate),
               let line = String(data: data, encoding: .utf8) {
                print(line)
            }

            if (index + 1) % 200 == 0 {
                FileHandle.standardError.write("parsed \(index + 1)/\(rows.count)\n".data(using: .utf8)!)
            }
        }
    }
}

private final class SystemDictionaryTranslationParser {
    private let partPattern = [
        "phrasal verb",
        "modal verb",
        "auxiliary verb",
        "noun",
        "verb",
        "adjective",
        "adverb",
        "pronoun",
        "preposition",
        "conjunction",
        "interjection",
        "determiner",
        "exclamation",
        "abbreviation"
    ].joined(separator: "|")

    func translation(for word: String) -> (String?, [DefinitionGroup], String) {
        let query = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return (nil, [], "empty_word") }

        guard let rawDefinition = copyDefinition(for: query) else {
            return (nil, [], "dictionary_miss")
        }

        let normalized = normalize(rawDefinition)
        let groups = parseGroups(from: normalized, query: query)
        let translation = format(groups: groups)

        guard let translation, isUsableTranslation(translation) else {
            return (nil, groups, "parse_failed")
        }

        return (translation, groups, "ok")
    }

    private func copyDefinition(for word: String) -> String? {
        let nsWord = word as NSString
        let range = CFRange(location: 0, length: nsWord.length)
        guard let unmanagedDefinition = DCSCopyTextDefinition(nil, word as CFString, range) else {
            return nil
        }
        return unmanagedDefinition.takeRetainedValue() as String
    }

    private func normalize(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .replacingOccurrences(of: "❑", with: " ")
            .replacingOccurrences(of: "•", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseGroups(from text: String, query: String) -> [DefinitionGroup] {
        let sections = splitPartOfSpeechSections(text: text, query: query)
        let parsedSections: [DefinitionGroup] = sections.compactMap { section in
            let definitions = parseDefinitions(from: section.text)
            guard !definitions.isEmpty else { return nil }
            return DefinitionGroup(
                partOfSpeech: abbreviation(for: section.partOfSpeech),
                definitions: definitions
            )
        }

        if !parsedSections.isEmpty {
            return merge(groups: parsedSections)
        }

        let fallbackDefinitions = parseDefinitions(from: text)
        guard !fallbackDefinitions.isEmpty else { return [] }
        return [DefinitionGroup(partOfSpeech: "", definitions: fallbackDefinitions)]
    }

    private func splitPartOfSpeechSections(text: String, query: String) -> [(partOfSpeech: String, text: String)] {
        let escapedQuery = NSRegularExpression.escapedPattern(for: query)
        let pattern = #"(?i)(?:^|\s)(?:\#(escapedQuery)|[A-Za-z][A-Za-z' -]{0,60})\s+(\#(partPattern))\s+/"#
        let matches = regexMatches(pattern: pattern, in: text)
        guard !matches.isEmpty else { return [] }

        let nsText = text as NSString
        var sections: [(partOfSpeech: String, text: String)] = []

        for index in matches.indices {
            let match = matches[index]
            let start = match.range.location
            let end = index + 1 < matches.count ? matches[index + 1].range.location : nsText.length
            guard end > start else { continue }

            let part = nsText.substring(with: match.range(at: 1)).lowercased()
            let sectionText = nsText.substring(with: NSRange(location: start, length: end - start))
            sections.append((partOfSpeech: part, text: sectionText))
        }

        return sections
    }

    private func parseDefinitions(from sectionText: String) -> [String] {
        let candidates = senseSegments(from: stripAfterReferenceMaterial(sectionText)).flatMap { segment in
            chineseDefinitionCandidates(from: segment)
        }

        var result: [String] = []
        var seen = Set<String>()

        for candidate in candidates {
            let cleaned = cleanDefinition(candidate)
            guard isUsableDefinition(cleaned), !seen.contains(cleaned) else { continue }
            seen.insert(cleaned)
            result.append(cleaned)
            if result.count >= 8 { break }
        }

        return result
    }

    private func stripAfterReferenceMaterial(_ text: String) -> String {
        let markers = [
            "Oxford Collocations Dictionary",
            "Extra Examples",
            "Synonyms",
            "Word Origin",
            "Wordfinder",
            "Idioms",
            "Phrasal Verbs",
            "Topics "
        ]

        var stripped = text
        for marker in markers {
            if let range = stripped.range(of: marker, options: [.caseInsensitive]) {
                stripped = String(stripped[..<range.lowerBound])
            }
        }
        return stripped
    }

    private func senseSegments(from text: String) -> [String] {
        let pattern = #"(?<![A-Za-z0-9])([1-9][0-9]?)\s+(?=\[|\(|[A-Za-z])"#
        let matches = regexMatches(pattern: pattern, in: text)
        let nsText = text as NSString

        guard !matches.isEmpty else { return [text] }

        var segments: [String] = []
        for index in matches.indices {
            let start = matches[index].range.location
            let end = index + 1 < matches.count ? matches[index + 1].range.location : nsText.length
            guard end > start else { continue }
            segments.append(nsText.substring(with: NSRange(location: start, length: end - start)))
        }
        return segments
    }

    private func chineseDefinitionCandidates(from text: String) -> [String] {
        let pattern = #"[一-龥][一-龥，、；：（）《》“”‘’·…-]{1,100}"#
        let matches = regexMatches(pattern: pattern, in: text)
        let nsText = text as NSString
        return matches.map { nsText.substring(with: $0.range) }
    }

    private func cleanDefinition(_ text: String) -> String {
        text
            .replacingOccurrences(of: "；；", with: "；")
            .replacingOccurrences(of: "，，", with: "，")
            .trimmingCharacters(in: CharacterSet(charactersIn: " ，,；;：:+-–—。！？ "))
    }

    private func isUsableDefinition(_ text: String) -> Bool {
        guard text.count >= 2, text.count <= 60 else { return false }
        guard text.range(of: #"[一-龥]"#, options: .regularExpression) != nil else { return false }
        guard text.range(of: #"[A-Za-z]"#, options: .regularExpression) == nil else { return false }

        let blockedExact = Set([
            "动词形式",
            "词族",
            "牛津搭配词典",
            "更多例句",
            "同义词辨析",
            "词源",
            "英式英语",
            "美国英语",
            "美式英语",
            "正式",
            "非正式",
            "尤用于美式英语",
            "尤用于英式英语"
        ])
        guard !blockedExact.contains(text) else { return false }

        let blockedFragments = [
            "点击查看",
            "另见",
            "比较",
            "参见",
            "以上各词",
            "均含",
            "以下均",
            "源自",
            "中古英语",
            "古英语",
            "拉丁语",
            "法语",
            "希腊语"
        ]
        guard !blockedFragments.contains(where: { text.contains($0) }) else { return false }

        let sentenceEndCount = text.filter { "。！？".contains($0) }.count
        guard sentenceEndCount == 0 else { return false }

        return true
    }

    private func merge(groups: [DefinitionGroup]) -> [DefinitionGroup] {
        var merged: [DefinitionGroup] = []
        var indexesByPart: [String: Int] = [:]

        for group in groups {
            if let index = indexesByPart[group.partOfSpeech] {
                let combined = unique(merged[index].definitions + group.definitions)
                merged[index] = DefinitionGroup(partOfSpeech: group.partOfSpeech, definitions: combined)
            } else {
                indexesByPart[group.partOfSpeech] = merged.count
                merged.append(DefinitionGroup(partOfSpeech: group.partOfSpeech, definitions: unique(group.definitions)))
            }
        }

        return merged
    }

    private func unique(_ values: [String]) -> [String] {
        var result: [String] = []
        var seen = Set<String>()
        for value in values where !seen.contains(value) {
            seen.insert(value)
            result.append(value)
        }
        return result
    }

    private func format(groups: [DefinitionGroup]) -> String? {
        guard !groups.isEmpty else { return nil }

        var pieces: [String] = []
        for group in groups {
            let definitions = group.definitions.prefix(6).joined(separator: "；")
            guard !definitions.isEmpty else { continue }
            if group.partOfSpeech.isEmpty {
                pieces.append(definitions)
            } else {
                pieces.append("\(group.partOfSpeech) \(definitions)")
            }
        }

        var output = pieces.joined(separator: "；")
        while output.count > 260, let lastSeparator = output.lastIndex(of: "；") {
            output = String(output[..<lastSeparator])
        }

        return output.isEmpty ? nil : output
    }

    private func isUsableTranslation(_ text: String) -> Bool {
        guard text.count >= 2, text.count <= 260 else { return false }
        guard text.range(of: #"[一-龥]"#, options: .regularExpression) != nil else { return false }

        let letters = text.filter { $0.isLetter && !$0.isChinese }
        let allowedLetters = text
            .replacingOccurrences(of: "n.", with: "")
            .replacingOccurrences(of: "v.", with: "")
            .replacingOccurrences(of: "adj.", with: "")
            .replacingOccurrences(of: "adv.", with: "")
            .replacingOccurrences(of: "pron.", with: "")
            .replacingOccurrences(of: "prep.", with: "")
            .replacingOccurrences(of: "conj.", with: "")
            .replacingOccurrences(of: "det.", with: "")
            .replacingOccurrences(of: "interj.", with: "")
            .replacingOccurrences(of: "excl.", with: "")
            .replacingOccurrences(of: "abbr.", with: "")
            .replacingOccurrences(of: "phr.v.", with: "")
            .replacingOccurrences(of: "modal v.", with: "")
            .replacingOccurrences(of: "aux.v.", with: "")
            .filter { $0.isLetter && !$0.isChinese }

        return letters.count - allowedLetters.count <= 40
    }

    private func abbreviation(for part: String) -> String {
        switch part {
        case "noun": return "n."
        case "verb": return "v."
        case "adjective": return "adj."
        case "adverb": return "adv."
        case "pronoun": return "pron."
        case "preposition": return "prep."
        case "conjunction": return "conj."
        case "interjection": return "interj."
        case "determiner": return "det."
        case "exclamation": return "excl."
        case "abbreviation": return "abbr."
        case "phrasal verb": return "phr.v."
        case "modal verb": return "modal v."
        case "auxiliary verb": return "aux.v."
        default: return part
        }
    }

    private func regexMatches(pattern: String, in text: String) -> [NSTextCheckingResult] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(location: 0, length: (text as NSString).length)
        return regex.matches(in: text, range: range)
    }
}

private extension Character {
    var isChinese: Bool {
        unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(Int(scalar.value))
        }
    }
}
