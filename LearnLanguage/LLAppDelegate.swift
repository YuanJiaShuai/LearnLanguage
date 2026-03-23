//
//  LLAppDelegate.swift
//  LearnLanguage
//
//  Created by Admin on 2026/2/3.
//

import AppKit
import Cocoa

@main
class LLAppDelegate: NSObject, NSApplicationDelegate {
    
    // MARK: - Properties
    
    /// 主窗口
    var mainWindow: NSWindow?
    
    // MARK: - Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 0. 确保应用跟随系统外观
        NSApp.appearance = nil
        // 1. 执行应用初始化（包括 MMKV、数据库、键盘快捷键等）
        LLAppInitializer.shared.performStartupInitialization()
        
        // 2. 初始化状态栏
        setupStatusBar()
        // 3. 创建主窗口（但不显示）
        setupMainWindow()
        
        LLLogger.info("🎉 应用启动完成！")
    }
    
    // MARK: - Setup
    
    private func setupStatusBar() {
        let manager = LLStatusBarManager.shared
        
        // 设置点击回调
        manager.onStatusBarClicked = { [weak self] in
            self?.handleStatusBarClick()
        }
        
        // 初始化状态栏
        manager.setupStatusBar()
    }
    
    private func setupMainWindow() {
        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        mainWindow?.title = ""
        mainWindow?.titleVisibility = .hidden
        mainWindow?.contentViewController = LLMainViewController()
        mainWindow?.center()
        mainWindow?.delegate = self
        
        // 禁止调整窗口大小
        mainWindow?.styleMask.remove(.resizable)
        
        // 设置固定大小
        mainWindow?.minSize = NSSize(width: 900, height: 600)
        mainWindow?.maxSize = NSSize(width: 900, height: 600)
        
        LLLogger.info("✅ 主窗口已创建（隐藏状态）")
    }
    
    // MARK: - Status Bar Actions
    
    private func handleStatusBarClick() {
        // 如果是打字练习模式，显示打字练习浮动窗口
        if LLStatusBarManager.shared.isTypingPracticeMode {
            LLStatusBarTypingPractice.shared.show()
        } else {
            // 否则显示主窗口
            showMainWindow()
        }
    }
    
    // MARK: - Window Management
    
    @objc func showMainWindow() {
        LLLogger.info("📱 显示主窗口")
        
        // 检查窗口是否存在或已被释放
        if mainWindow == nil || mainWindow?.contentView == nil {
            LLLogger.warn("⚠️ 主窗口为 nil 或已释放，重新创建")
            setupMainWindow()
        }
        
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func createFloatingPanel() {
        let panelWidth: CGFloat = 280
        let panelHeight: CGFloat = 160
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let origin = NSPoint(x: screenFrame.midX - panelWidth / 2, y: screenFrame.midY - panelHeight / 2)
        let window = NSWindow(contentRect: NSRect(origin: origin, size: NSSize(width: panelWidth, height: panelHeight)), styleMask: [.borderless], backing: .buffered, defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = false
        window.isMovableByWindowBackground = true
        let effect = NSVisualEffectView(frame: window.contentView!.bounds)
        effect.autoresizingMask = [.width, .height]
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 10
        effect.layer?.masksToBounds = true
        effect.alphaValue = LLSettingsStore.shared.settings.floatingPanelAlpha
        window.contentView = effect
        window.orderFront(nil)
    }

    // MARK: - Actions
    
    @objc func toggleTypingPracticeMode() {
        // 切换打字练习浮窗的显示/隐藏
        LLStatusBarTypingPractice.shared.toggleVisibility()
    }
    
    @objc func exitApp() {
        NSApp.terminate(self)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // 清理资源
    }

    /// 关闭可恢复状态，避免 NSXPCDecoder 用 NSObject 作为允许类解码导致的控制台警告及 "decode: bad range" 错误。
    /// 若曾开启过恢复，旧的状态数据可能已损坏，关闭后不再尝试解码即可消除报错。
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }
}

// MARK: - NSWindowDelegate

extension LLAppDelegate: NSWindowDelegate {
    
    /// 窗口即将关闭时调用
    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow, window == mainWindow {
            LLLogger.info("🔄 主窗口即将关闭，清理引用")
            // 将 mainWindow 设为 nil，下次打开时会重新创建
            mainWindow = nil
        }
    }
    
    /// 窗口是否应该关闭（可选）
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        // 允许关闭窗口
        return true
    }
}
