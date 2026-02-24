//
//  LLKeyboardShortcutManager.swift
//  LearnLanguage
//

import Cocoa
import Carbon

class LLKeyboardShortcutManager: NSObject {
    private var eventMonitor: Any?
    
    static let shared = LLKeyboardShortcutManager()
    
    private override init() {
        super.init()
        setupGlobalHotkey()
    }
    
    private func setupGlobalHotkey() {
        // 监听键盘事件
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] (event) in
            // 检查是否按下 Command+Shift+T (用于切换打字练习模式)
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 11 {
                // T 键的虚拟键码是 11
                self?.toggleTypingPracticeMode()
            }
        }
    }
    
    private func toggleTypingPracticeMode() {
        // 调用AppDelegate的方法来切换打字练习模式
        DispatchQueue.main.async {
            if let appDelegate = NSApp.delegate as? LLAppDelegate {
                appDelegate.toggleTypingPracticeMode()
            }
        }
    }
    
    deinit {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
