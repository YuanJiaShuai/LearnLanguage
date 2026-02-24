//
//  LLMMKVKeys.swift
//  LearnLanguage
//
//  MMKV 配置键定义
//

import Foundation

/// MMKV 配置键枚举
enum LLMMKVKeys {
    
    // MARK: - UI 设置
    
    /// 主题模式
    static let themeMode = "theme_mode"
    
    /// 字体大小
    static let fontSize = "font_size"
    
    /// 窗口位置和大小
    static let windowFrame = "window_frame"
    
    /// 侧边栏是否展开
    static let sidebarExpanded = "sidebar_expanded"
    
    /// 侧边栏宽度
    static let sidebarWidth = "sidebar_width"
    
    // MARK: - 学习设置
    
    /// 当前选中的词库 ID
    static let currentListId = "current_list_id"
    
    /// 是否处于打字练习模式
    static let isTypingPracticeMode = "is_typing_practice_mode"
    
    /// 每日学习目标（单词数）
    static let dailyGoal = "daily_goal"
    
    /// 是否自动播放音频
    static let autoPlayAudio = "auto_play_audio"
    
    /// 复习间隔（小时）
    static let reviewInterval = "review_interval"
    
    /// 每日新学单词数
    static let newWordsPerDay = "new_words_per_day"
    
    /// 每日复习单词数
    static let reviewCountPerDay = "review_count_per_day"
    
    /// 答错单词重学次数
    static let wrongWordRetryCount = "wrong_word_retry_count"
    
    /// 复习模式（0: 极简模式, 1: 艾宾浩斯曲线）
    static let reviewMode = "review_mode"
    
    // MARK: - 显示设置
    
    /// 状态栏是否显示音标
    static let statusBarShowPhonetic = "status_bar_show_phonetic"
    
    /// 状态栏是否显示释义
    static let statusBarShowMeaning = "status_bar_show_meaning"
    
    /// 状态栏最大显示长度
    static let statusBarMaxLength = "status_bar_max_length"
    
    /// 状态栏单词切换间隔（秒）
    static let statusBarInterval = "status_bar_interval"
    
    /// 状态栏显示内容类型（0: 仅单词, 1: 单词+音标, 2: 单词+简易释义）
    static let statusBarDisplayType = "status_bar_display_type"
    
    /// 浮动窗口透明度
    static let floatingPanelAlpha = "floating_panel_alpha"
    
    /// 是否显示反馈按钮
    static let showFeedbackButtons = "show_feedback_buttons"
    
    // MARK: - 发音设置
    
    /// 是否启用发音
    static let pronunciationEnabled = "pronunciation_enabled"
    
    /// 发音提供者（system/youdao/google）
    static let pronunciationProvider = "pronunciation_provider"
    
    /// 发音口音（us/uk/au）
    static let pronunciationAccent = "pronunciation_accent"
    
    /// 发音语速（0.1-1.0）
    static let pronunciationRate = "pronunciation_rate"
    
    // MARK: - 打字练习设置
    
    /// 是否启用打字练习
    static let typingPracticeEnabled = "typing_practice_enabled"
    
    /// 打字练习是否显示释义
    static let typingPracticeShowMeaning = "typing_practice_show_meaning"
    
    // MARK: - 其他设置
    
    /// 是否开机自启动
    static let launchAtLogin = "launch_at_login"
    
    /// 当前学习语言
    static let currentLanguage = "current_language"
    
    // MARK: - 导入相关
    
    /// 是否已导入词库列表
    static let hasImportedWordLists = "HasImportedWordLists"
    
    /// 最后导入时间
    static let lastImportTime = "last_import_time"
    
    /// 最后导入的版本号
    static let lastImportVersion = "last_import_version"
    
    // MARK: - 统计相关
    
    /// 总学习单词数
    static let totalLearnedWords = "total_learned_words"
    
    /// 总学习时长（秒）
    static let totalStudyTime = "total_study_time"
    
    /// 连续学习天数
    static let continuousStudyDays = "continuous_study_days"
    
    /// 最后学习日期
    static let lastStudyDate = "last_study_date"
    
    // MARK: - 应用信息
    
    /// 首次启动日期
    static let firstLaunchDate = "first_launch_date"
    
    /// 应用版本号
    static let appVersion = "app_version"
    
    /// 用户语言
    static let userLanguage = "user_language"
    
    /// 是否已经启动过应用
    static let hasLaunched = "has_launched"
}

