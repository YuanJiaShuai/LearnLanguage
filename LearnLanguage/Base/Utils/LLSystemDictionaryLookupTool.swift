//
//  LLSystemDictionaryLookupTool.swift
//  LearnLanguage
//
//  Temporary local tool for reading entries from the macOS Dictionary app.
//

import Foundation
import CoreServices

struct LLSystemDictionaryLookupResult: Codable, Equatable {
    let query: String
    let headword: String
    let phonetics: [String]
    let partsOfSpeech: [String]
    let meanings: [LLSystemDictionaryMeaning]
    let examples: [LLSystemDictionaryExample]
    let rawDefinition: String
}

struct LLSystemDictionaryMeaning: Codable, Equatable {
    let order: Int
    let english: String
    let chinese: String?
}

struct LLSystemDictionaryExample: Codable, Equatable {
    let sentenceEn: String
    let sentenceCn: String?
}

final class LLSystemDictionaryLookupTool {
    static let shared = LLSystemDictionaryLookupTool()

    private init() {}

    func lookup(_ word: String, requireTargetWord: Bool = true) -> LLSystemDictionaryLookupResult? {
        let query = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return nil }

        let nsQuery = query as NSString
        let range = CFRange(location: 0, length: nsQuery.length)

        guard let unmanagedDefinition = DCSCopyTextDefinition(nil, query as CFString, range) else {
            return nil
        }

        let rawDefinition = unmanagedDefinition.takeRetainedValue() as String
        let cleanedDefinition = normalizeDefinitionForDisplay(rawDefinition)

        return LLSystemDictionaryLookupResult(
            query: query,
            headword: query,
            phonetics: extractPhonetics(from: cleanedDefinition),
            partsOfSpeech: extractPartsOfSpeech(from: cleanedDefinition),
            meanings: extractMeanings(from: cleanedDefinition),
            examples: extractExamples(from: rawDefinition, query: query, requireTargetWord: requireTargetWord),
            rawDefinition: cleanedDefinition
        )
    }

    func rawDefinition(for word: String) -> String? {
        lookup(word)?.rawDefinition
    }

    func examples(for word: String, limit: Int = 4, requireTargetWord: Bool = true) -> [LLSystemDictionaryExample] {
        Array((lookup(word, requireTargetWord: requireTargetWord)?.examples ?? []).prefix(max(limit, 0)))
    }
}

private extension LLSystemDictionaryLookupTool {
    func normalizeDefinitionForDisplay(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func extractPhonetics(from text: String) -> [String] {
        uniqueMatches(pattern: #"/[^/\n]{1,50}/"#, in: text)
    }

    func extractPartsOfSpeech(from text: String) -> [String] {
        let knownParts = [
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
        ]

        let lowerText = text.lowercased()
        return knownParts.filter { lowerText.contains($0) }
    }

    func extractMeanings(from text: String) -> [LLSystemDictionaryMeaning] {
        let pattern = #"(?:(?:^|\s)([1-9][0-9]?)\s+)(.{8,260}?)([\u4E00-\u9FFF][^A-Za-z]{0,140})(?=\s[1-9][0-9]?\s+| Topics | Word Origin | Idioms | Oxford |$)"#
        let matches = regexMatches(pattern: pattern, in: text)

        return matches.compactMap { match in
            guard match.numberOfRanges >= 4 else { return nil }
            let nsText = text as NSString
            let orderText = nsText.substring(with: match.range(at: 1))
            let english = cleanupMeaning(nsText.substring(with: match.range(at: 2)))
            let chinese = cleanupMeaning(nsText.substring(with: match.range(at: 3)))
            guard let order = Int(orderText), !english.isEmpty else { return nil }
            return LLSystemDictionaryMeaning(
                order: order,
                english: english,
                chinese: chinese.isEmpty ? nil : chinese
            )
        }
    }

    func extractExamples(from text: String, query: String, requireTargetWord: Bool) -> [LLSystemDictionaryExample] {
        let preparedText = prepareDefinitionForExampleExtraction(text)
        let pattern = #"(?<![A-Za-z])([A-Z0-9"“‘'(][A-Za-z0-9 "'’‘“”,;:()\[\]\-$%/+=&—–-]{2,260}[.!?])\s*([\u4E00-\u9FFF][\u4E00-\u9FFF0-9０-９，、；：：“”‘’（）《》〈〉—…·\s,.:%/／-]{0,180}[。！？]?)"#
        let matches = regexMatches(pattern: pattern, in: preparedText)
        let nsText = preparedText as NSString

        var examples: [LLSystemDictionaryExample] = []
        var seen = Set<String>()

        for match in matches where match.numberOfRanges >= 3 {
            let sentenceEn = cleanupEnglishExample(nsText.substring(with: match.range(at: 1)))
            let sentenceCn = cleanupChineseExample(nsText.substring(with: match.range(at: 2)))
            let key = sentenceEn.lowercased()

            guard isLikelyExample(sentenceEn), !seen.contains(key) else { continue }
            guard sentenceCn.isEmpty || isLikelyChineseTranslation(sentenceCn) else { continue }
            if requireTargetWord, !containsTargetWord(query, in: sentenceEn) {
                continue
            }

            seen.insert(key)
            examples.append(
                LLSystemDictionaryExample(
                    sentenceEn: sentenceEn,
                    sentenceCn: sentenceCn.isEmpty ? nil : sentenceCn
                )
            )
        }

        return examples
    }
    
    func prepareDefinitionForExampleExtraction(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .replacingOccurrences(of: "❑", with: " ")
            .replacingOccurrences(of: "•", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func uniqueMatches(pattern: String, in text: String) -> [String] {
        let matches = regexMatches(pattern: pattern, in: text)
        let nsText = text as NSString
        var values: [String] = []
        var seen = Set<String>()

        for match in matches {
            let value = nsText.substring(with: match.range).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty, !seen.contains(value) else { continue }
            seen.insert(value)
            values.append(value)
        }

        return values
    }

    func regexMatches(pattern: String, in text: String) -> [NSTextCheckingResult] {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: (text as NSString).length)
            return regex.matches(in: text, range: range)
        } catch {
            LLLogger.warn("Dictionary lookup regex failed: \(pattern), \(error)")
            return []
        }
    }

    func cleanupMeaning(_ text: String) -> String {
        cleanupCommonText(text)
            .replacingOccurrences(of: #"see also.*$"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func cleanupEnglishExample(_ text: String) -> String {
        cleanupCommonText(text)
            .replacingOccurrences(
                of: #"^(?:\([A-Za-z][A-Za-z\s'/-]{0,40}\)\s*)+"#,
                with: "",
                options: .regularExpression
            )
            .trimmingCharacters(in: CharacterSet(charactersIn: " -–—•"))
    }

    func cleanupChineseExample(_ text: String) -> String {
        cleanupCommonText(text)
            .trimmingCharacters(in: CharacterSet(charactersIn: " ，,；;：:+-–—•"))
    }

    func cleanupCommonText(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func isLikelyExample(_ text: String) -> Bool {
        let lowerText = text.lowercased()
        guard text.count >= 12, text.count <= 260 else { return false }
        guard text.range(of: #"[\u4E00-\u9FFF]"#, options: .regularExpression) == nil else { return false }
        guard text.range(of: #"[.!?]\s*$"#, options: .regularExpression) != nil else { return false }
        guard text.range(of: #"^[A-Za-z"“‘']"#, options: .regularExpression) != nil else { return false }
        guard text.split(whereSeparator: { $0.isWhitespace }).count >= 2 else { return false }

        let blockedFragments = [
            "anglo-norman",
            "from late latin",
            "from latin",
            "middle english",
            "old english",
            "word origin",
            "oxford collocations dictionary",
            "topics ",
            "see also ",
            "learner's definition",
            "entries found",
            "definition of ",
            "phrasal verbs",
            "wordfinder",
            "gave rise to"
        ]
        return !blockedFragments.contains { lowerText.contains($0) }
    }

    func isLikelyChineseTranslation(_ text: String) -> Bool {
        guard text.range(of: #"[\u4E00-\u9FFF]"#, options: .regularExpression) != nil else { return false }
        guard text.range(of: #"[。！？!?]\s*$"#, options: .regularExpression) != nil else { return false }
        return true
    }

    func containsTargetWord(_ query: String, in sentence: String) -> Bool {
        let queryParts = query
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        guard !queryParts.isEmpty else { return true }

        let normalizedSentence = sentence
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if queryParts.count > 1 {
            return normalizedSentence.contains(queryParts.joined(separator: " "))
        }

        let sentenceWords = Set(normalizedSentence.split(separator: " ").map(String.init))
        return !sentenceWords.isDisjoint(with: targetForms(for: queryParts[0]))
    }

    func targetForms(for word: String) -> Set<String> {
        var forms: Set<String> = [word]

        if word.count > 1 {
            forms.insert(word + "s")
            forms.insert(word + "es")
            forms.insert(word + "ed")
            forms.insert(word + "ing")
        }

        if word.hasSuffix("e"), word.count > 2 {
            let stem = String(word.dropLast())
            forms.insert(stem + "d")
            forms.insert(stem + "ing")
        }

        if word.hasSuffix("y"), word.count > 2 {
            let stem = String(word.dropLast())
            forms.insert(stem + "ies")
            forms.insert(stem + "ied")
        }

        let irregularForms: [String: [String]] = [
            "be": ["am", "are", "is", "was", "were", "been", "being"],
            "buy": ["bought", "buying", "buys"],
            "come": ["came", "coming", "comes"],
            "do": ["did", "done", "does", "doing"],
            "find": ["found", "finding", "finds"],
            "get": ["got", "gotten", "getting", "gets"],
            "give": ["gave", "given", "giving", "gives"],
            "go": ["went", "gone", "going", "goes"],
            "have": ["had", "has", "having"],
            "make": ["made", "making", "makes"],
            "run": ["ran", "running", "runs"],
            "say": ["said", "saying", "says"],
            "see": ["saw", "seen", "seeing", "sees"],
            "take": ["took", "taken", "taking", "takes"],
            "write": ["wrote", "written", "writing", "writes"]
        ]
        irregularForms[word]?.forEach { forms.insert($0) }

        return forms
    }
}
