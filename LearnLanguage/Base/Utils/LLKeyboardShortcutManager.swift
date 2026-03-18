//
//  LLKeyboardShortcutManager.swift
//  LearnLanguage
//
//  全局快捷键管理器（基于 HotKey 库）
//  负责注册/注销全局热键，并响应用户配置的快捷键动作
//

import Cocoa
import Carbon
import HotKey

final class LLKeyboardShortcutManager: NSObject {

    static let shared = LLKeyboardShortcutManager()

    // MARK: - HotKey 实例（强引用，否则会被释放）

    private var hotKeys: [String: HotKey] = [:]

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - 公开方法

    /// 注册所有快捷键（启动时 / 设置变更后调用）
    func registerAll() {
        let config = LLSettingsStore.shared.settings.shortcutConfig
        unregisterAll()

        register(id: "showMainWindow",    combo: config.showMainWindow)    { LLKeyboardShortcutManager.shared.handleShowMainWindow() }
        register(id: "nextWord",          combo: config.nextWord)          { LLKeyboardShortcutManager.shared.handleNextWord() }
        register(id: "markKnow",          combo: config.markKnow)          { LLKeyboardShortcutManager.shared.handleMarkKnow() }
        register(id: "markUnclear",       combo: config.markUnclear)       { LLKeyboardShortcutManager.shared.handleMarkUnclear() }
        register(id: "markUnknown",       combo: config.markUnknown)       { LLKeyboardShortcutManager.shared.handleMarkUnknown() }
        register(id: "playPronunciation", combo: config.playPronunciation) { LLKeyboardShortcutManager.shared.handlePlayPronunciation() }
        register(id: "toggleTypingMode",  combo: config.toggleTypingMode)  { LLKeyboardShortcutManager.shared.handleToggleTypingMode() }

        LLLogger.info("⌨️ 已注册 \(hotKeys.count) 个全局快捷键")
    }

    /// 注销所有快捷键
    func unregisterAll() {
        hotKeys.removeAll()
    }

    // MARK: - 私有：注册单个

    private func register(id: String, combo: LLKeyCombo, handler: @escaping () -> Void) {
        guard !combo.isEmpty,
              let key = Key(carbonKeyCode: combo.keyCode),
              let modifiers = cocoaModifiers(from: combo.modifiers) else { return }

        let hotKey = HotKey(key: key, modifiers: modifiers)
        hotKey.keyDownHandler = handler
        hotKeys[id] = hotKey
        LLLogger.info("  ✅ 注册快捷键 [\(id)]: \(combo.displayString)")
    }

    /// 将 Carbon modifier flags 转换为 NSEvent.ModifierFlags
    private func cocoaModifiers(from carbonFlags: UInt32) -> NSEvent.ModifierFlags? {
        var result: NSEvent.ModifierFlags = []
        if carbonFlags & UInt32(cmdKey)     != 0 { result.insert(.command) }
        if carbonFlags & UInt32(optionKey)  != 0 { result.insert(.option) }
        if carbonFlags & UInt32(shiftKey)   != 0 { result.insert(.shift) }
        if carbonFlags & UInt32(controlKey) != 0 { result.insert(.control) }
        return result.isEmpty ? nil : result
    }

    // MARK: - 动作处理

    private func handleShowMainWindow() {
        DispatchQueue.main.async {
            if let delegate = NSApp.delegate as? LLAppDelegate {
                delegate.showMainWindow()
            }
        }
    }

    private func handleNextWord() {
        DispatchQueue.main.async {
            LLStatusBarManager.shared.moveToNextWord()
        }
    }

    private func handleMarkKnow() {
        DispatchQueue.main.async {
            LLStatusBarManager.shared.recordFeedback(.know)
        }
    }

    private func handleMarkUnclear() {
        DispatchQueue.main.async {
            LLStatusBarManager.shared.recordFeedback(.unclear)
        }
    }

    private func handleMarkUnknown() {
        DispatchQueue.main.async {
            LLStatusBarManager.shared.recordFeedback(.unknown)
        }
    }

    private func handlePlayPronunciation() {
        DispatchQueue.main.async {
            LLStatusBarManager.shared.playCurrentWordPronunciation()
        }
    }

    private func handleToggleTypingMode() {
        DispatchQueue.main.async {
            if let delegate = NSApp.delegate as? LLAppDelegate {
                delegate.toggleTypingPracticeMode()
            }
        }
    }
}
