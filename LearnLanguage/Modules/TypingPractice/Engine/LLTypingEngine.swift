//
//  LLTypingEngine.swift
//  LearnLanguage
//
//  打字引擎 - 纯逻辑状态机，不依赖任何 UI 框架
//  参考 TypeLex 的设计，完全解耦业务逻辑和视图层
//

import Foundation

/// 打字引擎 - 负责管理单词打字的状态机
struct LLTypingEngine {
    
    // MARK: - State
    
    /// 当前目标单词
    let targetWord: String
    
    /// 当前光标位置（0-based index）
    /// 指向「下一个等待输入」的字符
    private(set) var cursorIndex: Int = 0
    
    /// 该单词累积错误次数
    private(set) var errorCount: Int = 0
    
    /// 开始时间（用于计算 WPM）
    private(set) var startedAt: Date?
    
    /// 标记是否刚发生错误（用于 UI 短暂震动或闪烁）
    private(set) var lastInputWasError: Bool = false
    
    // MARK: - Initialization
    
    init(targetWord: String) {
        self.targetWord = targetWord
    }
    
    // MARK: - Computed Properties
    
    /// 检查是否已完成该单词
    var isFinished: Bool {
        return cursorIndex >= targetWord.count
    }
    
    /// 取得目前已输入正确的部分
    var typedPrefix: String {
        return String(targetWord.prefix(cursorIndex))
    }
    
    /// 取得剩余未输入的部分
    var remainingSuffix: String {
        guard cursorIndex < targetWord.count else { return "" }
        let startIndex = targetWord.index(targetWord.startIndex, offsetBy: cursorIndex)
        return String(targetWord[startIndex...])
    }
    
    /// 获取当前应该输入的字符（如果还没完成）
    var currentTargetChar: Character? {
        guard !isFinished else { return nil }
        let targetCharIndex = targetWord.index(targetWord.startIndex, offsetBy: cursorIndex)
        return targetWord[targetCharIndex]
    }
    
    /// 计算准确率（百分比）
    var accuracy: Int {
        let totalInputs = cursorIndex + errorCount
        guard totalInputs > 0 else { return 100 }
        return Int(Double(cursorIndex) / Double(totalInputs) * 100)
    }
    
    /// 计算已用时间（秒）
    var elapsedTime: TimeInterval {
        guard let startedAt = startedAt else { return 0 }
        return Date().timeIntervalSince(startedAt)
    }
    
    /// 计算打字速度（字符/分钟）
    var speed: Int {
        guard elapsedTime > 0 else { return 0 }
        return Int(Double(cursorIndex) / (elapsedTime / 60.0))
    }
    
    // MARK: - Actions
    
    /// 处理使用者输入字符
    /// - Parameter char: 使用者输入的字符
    /// - Returns: 输入是否正确
    mutating func input(char: Character) -> Bool {
        // 如果已经结束，不处理
        if isFinished { return false }
        
        // 开始计时
        if cursorIndex == 0 && startedAt == nil {
            startedAt = Date()
        }
        
        // 重置错误旗标
        lastInputWasError = false
        
        // 取得当前目标字元
        let targetCharIndex = targetWord.index(targetWord.startIndex, offsetBy: cursorIndex)
        let targetChar = targetWord[targetCharIndex]
        
        // 比对（大小写不敏感）
        if char.lowercased() == targetChar.lowercased() {
            cursorIndex += 1
            return true
        } else {
            errorCount += 1
            lastInputWasError = true
            return false
        }
    }
    
    /// 重置引擎以练习新单词
    mutating func reset(newWord: String) {
        self = LLTypingEngine(targetWord: newWord)
    }
    
    /// 清空当前进度（重新开始当前单词）
    mutating func restart() {
        cursorIndex = 0
        errorCount = 0
        startedAt = nil
        lastInputWasError = false
    }
}

