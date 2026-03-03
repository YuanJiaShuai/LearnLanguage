//
//  LLLogger.swift
//  LearnLanguage
//
//  统一封装 CocoaLumberjack 日志配置与使用
//

import Foundation
import CocoaLumberjackSwift

/// 全局日志级别（CocoaLumberjackSwift 需要）
public var dynamicLogLevel: DDLogLevel = .verbose

/// 应用日志工具
enum LLLogger {
    
    private static func toMessageFormat(_ message: @autoclosure () -> String) -> DDLogMessageFormat {
        "\(message())"
    }
    
    /// 在应用启动时调用，完成日志系统初始化
    static func setup() {
        // 控制台日志（支持 Xcode 控制台颜色）
        DDLog.add(DDOSLogger.sharedInstance)
        
        // 文件日志：默认保留最近 7 天日志
        let fileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 小时滚动一次
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
        
        // 根据构建环境设置日志级别
        #if DEBUG
        dynamicLogLevel = .verbose
        #else
        dynamicLogLevel = .info
        #endif
        
        info("📂 日志系统已初始化（级别：\(dynamicLogLevel.rawValue)）")
        if let logFilePaths = (fileLogger.logFileManager as? DDLogFileManagerDefault)?.sortedLogFilePaths {
            info("📝 日志文件路径：\(logFilePaths.joined(separator: ", "))")
        }
    }
    
    // MARK: - 便捷封装
    
    static func debug(_ message: @autoclosure () -> String,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line) {
        DDLogDebug(toMessageFormat(message()), file: file, function: function, line: line)
    }
    
    static func info(_ message: @autoclosure () -> String,
                     file: StaticString = #file,
                     function: StaticString = #function,
                     line: UInt = #line) {
        DDLogInfo(toMessageFormat(message()), file: file, function: function, line: line)
    }
    
    static func warn(_ message: @autoclosure () -> String,
                     file: StaticString = #file,
                     function: StaticString = #function,
                     line: UInt = #line) {
        DDLogWarn(toMessageFormat(message()), file: file, function: function, line: line)
    }
    
    static func error(_ message: @autoclosure () -> String,
                      file: StaticString = #file,
                      function: StaticString = #function,
                      line: UInt = #line) {
        DDLogError(toMessageFormat(message()), file: file, function: function, line: line)
    }
}

