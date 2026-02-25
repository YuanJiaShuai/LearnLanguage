//
//  LLStatusBarTypingPractice.swift
//  LearnLanguage
//

import AppKit
import SnapKit

class LLStatusBarTypingPractice {
    private var window: NSWindow?
    private var viewController: LLTypingPracticeFloatingViewController?
    private(set) var isVisible = false  // 改为公开可读
    
    static let shared = LLStatusBarTypingPractice()
    
    private init() {}
    
    func show() {
        if window == nil {
            createWindow()
        }
        
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // 优先使用状态栏当前显示的单词
        if let currentListId = LLSettingsStore.shared.currentListId {
            LLTypingPracticeManager.shared.startPractice(listId: currentListId)
            
            // 优先获取状态栏当前显示的单词
            let wordToPractice = LLTypingPracticeManager.shared.getCurrentStatusBarWord() 
                ?? LLTypingPracticeManager.shared.getNextWord()
            
            if let word = wordToPractice {
                viewController?.startPractice(with: word, listId: currentListId)
            }
        }
        
        // 确保窗口获得焦点后，再次尝试聚焦输入框
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.window?.makeKey()
        }
        
        isVisible = true
    }
    
    func hide() {
        window?.orderOut(nil)
        isVisible = false
    }
    
    func toggleVisibility() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }
    
    private func createWindow() {
        // 从设置中读取浮窗宽高
        let settings = LLSettingsStore.shared.settings
        let panelWidth: CGFloat = settings.floatingPanelWidth
        let panelHeight: CGFloat = settings.floatingPanelHeight
        
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let origin = NSPoint(x: screenFrame.midX - panelWidth / 2, y: screenFrame.midY - panelHeight / 2)
        
        // 创建自定义的 Panel（可以接收键盘输入的无边框窗口）
        window = FloatingPanel(
            contentRect: NSRect(origin: origin, size: NSSize(width: panelWidth, height: panelHeight)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        window?.isOpaque = false
        window?.backgroundColor = .clear
        window?.level = .floating  // 永远在最上层
        window?.hasShadow = true
        window?.isMovableByWindowBackground = true
        window?.acceptsMouseMovedEvents = true
        window?.ignoresMouseEvents = false
        
        // 创建毛玻璃效果背景
        let effect = NSVisualEffectView(frame: window!.contentView!.bounds)
        effect.autoresizingMask = [.width, .height]
        effect.material = .hudWindow
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 12
        effect.layer?.masksToBounds = true
        effect.alphaValue = CGFloat(LLSettingsStore.shared.settings.floatingPanelAlpha)
        
        // 创建视图控制器
        viewController = LLTypingPracticeFloatingViewController()
        
        if let vc = viewController {
            // 将视图控制器的视图添加到毛玻璃效果上
            effect.addSubview(vc.view)
            vc.view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            // 设置回调
            vc.onWordCompleted = { [weak self] feedback in
                LLTypingPracticeManager.shared.recordResult(feedback: feedback)
                
                // 加载下一个单词（与状态栏同步）
                if let currentListId = LLSettingsStore.shared.currentListId {
                    LLTypingPracticeManager.shared.startPractice(listId: currentListId)
                    
                    // 获取下一个单词（此时状态栏已经刷新到下一个单词了）
                    if let nextWord = LLTypingPracticeManager.shared.getCurrentStatusBarWord() {
                        vc.startPractice(with: nextWord, listId: currentListId)
                    } else {
                        vc.resetView()
                        vc.targetWordLabel.stringValue = "没有更多单词了！"
                    }
                }
            }
        }
        
        window?.contentView = effect
    }
}

// MARK: - 自定义 Panel，允许无边框窗口接收键盘输入

class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
}
