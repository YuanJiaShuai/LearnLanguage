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

/// 应用显示语言
enum LLDisplayLanguage: String, CaseIterable, Codable {
    case english = "English"
    case simplifiedChinese = "简体中文"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .simplifiedChinese: return "简体中文"
        }
    }
    
    var languageCode: String {
        switch self {
        case .english: return "en"
        case .simplifiedChinese: return "zh-Hans"
        }
    }
}

/// 发音提供者类型
enum LLPronunciationProvider: String, Codable, CaseIterable {
    case local = "local"           // 本地 TTS
    case youdao = "youdao"         // 有道词典
    case google = "google"         // Google TTS (预留)
    case azure = "azure"           // Azure Speech (预留)
    
    var displayName: String {
        switch self {
        case .local: return NSLocalizedString("Pronunciation Local", comment: "")
        case .youdao: return NSLocalizedString("Pronunciation Youdao", comment: "")
        case .google: return NSLocalizedString("Pronunciation Google", comment: "")
        case .azure: return NSLocalizedString("Pronunciation Azure", comment: "")
        }
    }
}

/// 发音口音类型
enum LLPronunciationAccent: String, Codable, CaseIterable {
    case us = "us"     // 美式英语
    case uk = "uk"     // 英式英语
    
    var displayName: String {
        switch self {
        case .us: return NSLocalizedString("Accent US", comment: "")
        case .uk: return NSLocalizedString("Accent UK", comment: "")
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
        case .perLetter: return NSLocalizedString("Typing Per Letter", comment: "")
        case .wholeWord: return NSLocalizedString("Typing Whole Word", comment: "")
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
        case .after1Error: return NSLocalizedString("Auto Show After 1 Error", comment: "")
        case .after2Errors: return NSLocalizedString("Auto Show After 2 Errors", comment: "")
        case .after3Errors: return NSLocalizedString("Auto Show After 3 Errors", comment: "")
        case .after4Errors: return NSLocalizedString("Auto Show After 4 Errors", comment: "")
        case .after5Errors: return NSLocalizedString("Auto Show After 5 Errors", comment: "")
        case .never: return NSLocalizedString("Auto Show Never", comment: "")
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
        case .after1Error: return NSLocalizedString("Wrong Book After 1 Error", comment: "")
        case .after2Errors: return NSLocalizedString("Wrong Book After 2 Errors", comment: "")
        case .after3Errors: return NSLocalizedString("Wrong Book After 3 Errors", comment: "")
        case .after4Errors: return NSLocalizedString("Wrong Book After 4 Errors", comment: "")
        case .after5Errors: return NSLocalizedString("Wrong Book After 5 Errors", comment: "")
        case .never: return NSLocalizedString("Wrong Book Never", comment: "")
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

/// 语速配置
enum LLSpeechRate: Float, CaseIterable, Codable {
    case slow = 0.25
    case normal = 0.5
    case standard = 1.0
    case fast = 1.5
    case veryFast = 2.0
    
    var displayName: String {
        switch self {
        case .slow:     return NSLocalizedString("Speech Rate Slow", comment: "")
        case .normal:   return NSLocalizedString("Speech Rate Normal", comment: "")
        case .standard: return NSLocalizedString("Speech Rate Standard", comment: "")
        case .fast:     return NSLocalizedString("Speech Rate Fast", comment: "")
        case .veryFast: return NSLocalizedString("Speech Rate Very Fast", comment: "")
        }
    }
    
    static var allDisplayNames: [String] {
        allCases.map { $0.displayName }
    }
    
    static func from(rate: Float) -> LLSpeechRate {
        return allCases.min(by: { abs($0.rawValue - rate) < abs($1.rawValue - rate) }) ?? .standard
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
        case .once:      return NSLocalizedString("Playback Once", comment: "")
        case .every5s:   return NSLocalizedString("Playback Every 5s", comment: "")
        case .every10s:  return NSLocalizedString("Playback Every 10s", comment: "")
        case .every20s:  return NSLocalizedString("Playback Every 20s", comment: "")
        case .every60s:  return NSLocalizedString("Playback Every 60s", comment: "")
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

/// 快捷键组合
struct LLKeyCombo: Codable, Equatable {
    var keyCode: UInt32      // 虚拟键码
    var modifiers: UInt32    // Carbon modifier flags
    var displayString: String // 显示字符串，如 "⌘⇧L"
    
    static let empty = LLKeyCombo(keyCode: 0, modifiers: 0, displayString: "")
    
    var isEmpty: Bool { displayString.isEmpty }
}

/// 所有可配置的快捷键动作
struct LLShortcutConfig: Codable {
    var showMainWindow: LLKeyCombo
    var nextWord: LLKeyCombo
    var markKnow: LLKeyCombo
    var markUnclear: LLKeyCombo
    var markUnknown: LLKeyCombo
    var playPronunciation: LLKeyCombo
    var toggleTypingMode: LLKeyCombo
    
    static let `default` = LLShortcutConfig(
        showMainWindow:   LLKeyCombo(keyCode: 37, modifiers: 0x0100 | 0x0200, displayString: "⌘⇧L"),
        nextWord:         LLKeyCombo(keyCode: 45, modifiers: 0x0100 | 0x0200, displayString: "⌘⇧N"),
        markKnow:         LLKeyCombo(keyCode: 40, modifiers: 0x0100 | 0x0200, displayString: "⌘⇧K"),
        markUnclear:      LLKeyCombo(keyCode: 32, modifiers: 0x0100 | 0x0200, displayString: "⌘⇧U"),
        markUnknown:      LLKeyCombo(keyCode: 38, modifiers: 0x0100 | 0x0200, displayString: "⌘⇧J"),
        playPronunciation:LLKeyCombo(keyCode: 35, modifiers: 0x0100 | 0x0200, displayString: "⌘⇧P"),
        toggleTypingMode: LLKeyCombo(keyCode: 17, modifiers: 0x0100 | 0x0200, displayString: "⌘⇧T")
    )
}

/// 应用设置（本地存储）
struct LLAppSettings: Codable {
    var displayLanguage: LLDisplayLanguage  // 应用显示语言
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
    var launchAtLogin: Bool
    var shortcutConfig: LLShortcutConfig

    static let `default` = LLAppSettings(
        displayLanguage: .english,
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
        pronunciationRate: 1.0,
        newWordsPerDay: 20,
        reviewCountPerDay: 50,
        reminderEnabled: false,
        reminderTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date(),
        typingPracticeShowMeaning: true,
        typingDictationMode: false,
        typingInputStyle: .perLetter,
        autoShowAnswerAfterErrors: 3,
        launchAtLogin: false,
        shortcutConfig: .default
    )
}
