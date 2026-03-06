//
//  LLAppSettings.swift
//  LearnLanguage
//

import Foundation

/// 支持学习的语言（先占定 3 类，后续可扩展）
enum LLLearningLanguage: String, CaseIterable, Codable {
    case english = "英语"
    case japanese = "日语"
    case korean = "韩语"
}

/// 发音提供者类型
enum LLPronunciationProvider: String, Codable, CaseIterable {
    case local = "local"           // 本地 TTS
    case youdao = "youdao"         // 有道词典
    case google = "google"         // Google TTS (预留)
    case azure = "azure"           // Azure Speech (预留)
    
    var displayName: String {
        switch self {
        case .local: return "本地发音"
        case .youdao: return "有道发音"
        case .google: return "Google 发音"
        case .azure: return "Azure 发音"
        }
    }
}

/// 发音口音类型
enum LLPronunciationAccent: String, Codable, CaseIterable {
    case us = "us"     // 美式英语
    case uk = "uk"     // 英式英语
    
    var displayName: String {
        switch self {
        case .us: return "美式发音"
        case .uk: return "英式发音"
        }
    }
    
    var flag: String {
        switch self {
        case .us: return "🇺🇸"
        case .uk: return "🇬🇧"
        }
    }
}

/// 打字练习输入框样式
enum LLTypingInputStyle: String, Codable, CaseIterable {
    case perLetter = "per_letter"     // 每个字母一个下划线
    case wholeWord = "whole_word"     // 整个单词一个下划线
    
    var displayName: String {
        switch self {
        case .perLetter: return "每个字母一个下划线（_ _ _ _ _）"
        case .wholeWord: return "整个单词一个下划线（_____）"
        }
    }
}

/// 自动显示答案配置
enum LLAutoShowAnswerOption: Int, CaseIterable, Codable {
    case after1Error = 1
    case after2Errors = 2
    case after3Errors = 3
    case after4Errors = 4
    case after5Errors = 5
    case never = 999
    
    var displayName: String {
        switch self {
        case .after1Error: return "错误1次后"
        case .after2Errors: return "错误2次后"
        case .after3Errors: return "错误3次后"
        case .after4Errors: return "错误4次后"
        case .after5Errors: return "错误5次后"
        case .never: return "不自动显示"
        }
    }
    
    static var allDisplayNames: [String] {
        allCases.map { $0.displayName }
    }
    
    // 从错误次数获取对应的选项
    static func from(errorCount: Int) -> LLAutoShowAnswerOption {
        switch errorCount {
        case 1: return .after1Error
        case 2: return .after2Errors
        case 3: return .after3Errors
        case 4: return .after4Errors
        case 5: return .after5Errors
        default: return .never
        }
    }
}

/// 记录到错题本配置
enum LLAddToWrongBookOption: Int, CaseIterable, Codable {
    case after1Error = 1
    case after2Errors = 2
    case after3Errors = 3
    case after4Errors = 4
    case after5Errors = 5
    case never = 999
    
    var displayName: String {
        switch self {
        case .after1Error: return "错误1次后"
        case .after2Errors: return "错误2次后"
        case .after3Errors: return "错误3次后"
        case .after4Errors: return "错误4次后"
        case .after5Errors: return "错误5次后"
        case .never: return "不记录"
        }
    }
    
    static var allDisplayNames: [String] {
        allCases.map { $0.displayName }
    }
    
    // 从错误次数获取对应的选项
    static func from(errorCount: Int) -> LLAddToWrongBookOption {
        switch errorCount {
        case 1: return .after1Error
        case 2: return .after2Errors
        case 3: return .after3Errors
        case 4: return .after4Errors
        case 5: return .after5Errors
        default: return .never
        }
    }
}

/// 播放间隔配置
enum LLPlaybackInterval: Int, CaseIterable, Codable {
    case once = 0           // 只播放1次
    case every5s = 5        // 5秒播放一次
    case every10s = 10      // 10秒播放一次
    case every20s = 20      // 20秒播放一次
    case every60s = 60      // 60秒播放一次
    
    var displayName: String {
        switch self {
        case .once: return "只播放1次"
        case .every5s: return "5秒播放一次"
        case .every10s: return "10秒播放一次"
        case .every20s: return "20秒播放一次"
        case .every60s: return "60秒播放一次"
        }
    }
    
    static var allDisplayNames: [String] {
        allCases.map { $0.displayName }
    }
    
    // 从秒数获取对应的选项
    static func from(seconds: Int) -> LLPlaybackInterval {
        switch seconds {
        case 0: return .once
        case 5: return .every5s
        case 10: return .every10s
        case 20: return .every20s
        case 60: return .every60s
        default: return .once
        }
    }
}

/// 应用设置（本地存储）
struct LLAppSettings: Codable {
    var currentLanguage: LLLearningLanguage
    var currentListId: String?
    var statusBarShowPhonetic: Bool
    var statusBarMaxLength: Int
    var statusBarShowContent: Bool  // 状态栏是否显示内容
    var statusBarContentWidth: Int  // 状态栏显示内容的宽度（135-300）
    var showFeedbackButtons: Bool   // 是否显示反馈按钮
    
    // 新增：状态栏显示内容细分控制
    var statusBarShowWord: Bool      // 是否显示单词
    var statusBarShowPhoneticSymbol: Bool  // 是否显示音标
    var statusBarShowMeaning: Bool   // 是否显示释义
    var statusBarAutoScroll: Bool    // 释义不够显示时是否自动滚动
    var statusBarPlaybackInterval: Int  // 播放间隔（秒）
    
    var floatingPanelAlpha: Double
    var floatingPanelWidth: CGFloat   // 浮窗宽度
    var floatingPanelHeight: CGFloat  // 浮窗高度
    var pronunciationEnabled: Bool
    var pronunciationProvider: LLPronunciationProvider
    var pronunciationAccent: LLPronunciationAccent
    var pronunciationRate: Float  // 语速 0.0-1.0
    var newWordsPerDay: Int
    var reviewCountPerDay: Int
    var reminderEnabled: Bool
    var reminderTime: Date
    var typingPracticeShowMeaning: Bool
    var typingDictationMode: Bool  // 听写模式（隐藏单词）
    var typingInputStyle: LLTypingInputStyle  // 打字练习输入框样式
    var autoShowAnswerAfterErrors: Int  // 自动显示答案（错误N次后）
    var addToWrongBookAfterErrors: Int  // 记录到错题本（错误N次后）
    var launchAtLogin: Bool

    static let `default` = LLAppSettings(
        currentLanguage: .english,
        currentListId: nil,
        statusBarShowPhonetic: false,
        statusBarMaxLength: 20,
        statusBarShowContent: true,
        statusBarContentWidth: 150,
        showFeedbackButtons: true,
        statusBarShowWord: true,
        statusBarShowPhoneticSymbol: true,
        statusBarShowMeaning: true,
        statusBarAutoScroll: true,
        statusBarPlaybackInterval: 0,
        floatingPanelAlpha: 0.55,
        floatingPanelWidth: 400,
        floatingPanelHeight: 200,
        pronunciationEnabled: true,
        pronunciationProvider: .local,
        pronunciationAccent: .us,
        pronunciationRate: 0.4,
        newWordsPerDay: 20,
        reviewCountPerDay: 50,
        reminderEnabled: false,
        reminderTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
        typingPracticeShowMeaning: true,
        typingDictationMode: false,
        typingInputStyle: .perLetter,
        autoShowAnswerAfterErrors: 3,
        addToWrongBookAfterErrors: 2,
        launchAtLogin: false
    )
}
