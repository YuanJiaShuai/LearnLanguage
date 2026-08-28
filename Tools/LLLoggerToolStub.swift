import Foundation

enum LLLogger {
    static func warn(_ message: @autoclosure () -> String) {
        FileHandle.standardError.write((message() + "\n").data(using: .utf8)!)
    }
}
