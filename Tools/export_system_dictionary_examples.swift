import Foundation

private struct DictionaryExampleExport: Codable {
    let word: String
    let examples: [LLSystemDictionaryExample]
}

@main
struct DictionaryExampleExporter {
    static func main() {
        let input = FileHandle.standardInput.readDataToEndOfFile()
        let words = (try? JSONDecoder().decode([String].self, from: input)) ?? []

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]

        for (index, word) in words.enumerated() {
            let lookupWord = word
                .split(whereSeparator: \.isNewline)
                .first
                .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) } ?? word
            let examples = LLSystemDictionaryLookupTool.shared.examples(
                for: lookupWord,
                limit: Int.max,
                requireTargetWord: true
            )
            let output = DictionaryExampleExport(word: word, examples: examples)

            if let data = try? encoder.encode(output),
               let line = String(data: data, encoding: .utf8) {
                print(line)
            }

            if (index + 1) % 100 == 0 {
                FileHandle.standardError.write("exported \(index + 1)/\(words.count)\n".data(using: .utf8)!)
            }
        }
    }
}
