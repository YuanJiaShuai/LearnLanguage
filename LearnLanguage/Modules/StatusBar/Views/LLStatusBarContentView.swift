//
//  LLStatusBarContentView.swift
//  LearnLanguage
//
//  状态栏内容视图 - 自定义绘制单词、音标和释义
//

import AppKit
import SnapKit

final class LLStatusBarContentView: NSControl {
    
    // MARK: - Properties
    
    var statusItem: NSStatusItem
    var clicked: Bool = false
    
    var wordText: String = "LearnLanguage"
    var phoneticText: String = ""
    var meaningText: String = ""
    
    // MARK: - UI Components
    
    private lazy var wordPhoneticView: LLWordPhoneticView = {
        let view = LLWordPhoneticView()
        view.wantsLayer = true
        return view
    }()
    
    private lazy var scrollingMeaningView: LLScrollingTextView = {
        let view = LLScrollingTextView(frame: .zero)
        view.wantsLayer = true
        return view
    }()
    
    private lazy var feedbackView: LLStatusBarFeedbackView = {
        let view = LLStatusBarFeedbackView(frame: .zero)
        view.wantsLayer = true
        view.alphaValue = 0 // 默认隐藏
        view.isHidden = true // 完全隐藏
        view.onFeedback = { [weak self] feedback in
            self?.handleFeedback(feedback)
        }
        return view
    }()
    
    // 追踪区域，用于检测鼠标进入/离开
    private var trackingArea: NSTrackingArea?
    
    // MARK: - Initialization
    
    init(statusItem: NSStatusItem, menu: NSMenu?) {
        self.statusItem = statusItem
        // 使用完整的状态栏高度，不留间距
        let height = NSStatusBar.system.thickness
        let width = statusItem.length
        super.init(frame: NSMakeRect(0, 0, width, height))
        self.menu = menu
        self.menu?.delegate = self
        self.wantsLayer = true
        
        // 调试：打印外观信息
        print("🎨 LLStatusBarContentView 初始化")
        print("🎨 effectiveAppearance: \(effectiveAppearance.name)")
        
        setupUI()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        print("🎨 LLStatusBarContentView 移动到窗口")
        print("🎨 window?.effectiveAppearance: \(window?.effectiveAppearance.name.rawValue ?? "nil")")
        print("🎨 effectiveAppearance: \(effectiveAppearance.name)")
    }
    
    override var intrinsicContentSize: NSSize {
        let height = NSStatusBar.system.thickness
        let width = statusItem.length
        return NSSize(width: width, height: height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(wordPhoneticView)
        addSubview(scrollingMeaningView)
        addSubview(feedbackView)
        
        // 单词音标视图在左侧，垂直居中，宽度自适应
        wordPhoneticView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
        }
        
        // 滚动视图在右侧，填充剩余空间
        scrollingMeaningView.snp.makeConstraints { make in
            make.left.equalTo(wordPhoneticView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-8)
            make.top.bottom.equalToSuperview()
        }
        
        // 反馈按钮和滚动视图重叠，位置和大小完全相同
        feedbackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollingMeaningView)
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        // 移除旧的追踪区域
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        
        // 创建新的追踪区域
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        showFeedbackView()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        hideFeedbackView()
    }
    
    private func showFeedbackView() {
        // 显示反馈按钮，隐藏滚动视图
        feedbackView.isHidden = false
        scrollingMeaningView.isHidden = true
        
        // 淡入动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            feedbackView.animator().alphaValue = 1
        }
    }
    
    private func hideFeedbackView() {
        // 淡出动画
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            feedbackView.animator().alphaValue = 0
        }, completionHandler: {
            // 动画完成后隐藏反馈按钮，显示滚动视图
            self.feedbackView.isHidden = true
            self.scrollingMeaningView.isHidden = false
        })
    }
    
    private func handleFeedback(_ feedback: LLWordFeedback) {
        // 通知 LLStatusBarManager 记录反馈
        LLStatusBarManager.shared.recordFeedback(feedback)
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 绘制背景
        if #available(macOS 10.14, *) {
            // 使用标准按钮属性代替废弃的方法
            if clicked {
                NSColor.selectedControlColor.withAlphaComponent(0.2).setFill()
                NSBezierPath(rect: bounds).fill()
            }
        } else {
            statusItem.drawStatusBarBackground(in: dirtyRect, withHighlight: clicked)
        }
    }
    
    override func updateLayer() {
        super.updateLayer()
        
        // 确定文字颜色（根据深色/浅色模式）
        var textColor: NSColor
        if #available(macOS 11.0, *) {
            if effectiveAppearance.name.rawValue.lowercased().contains("dark") {
                textColor = NSColor.white
            } else {
                textColor = NSColor.black
            }
        } else {
            textColor = clicked ? NSColor.white : NSColor.black
        }
        
        // 更新所有子视图的颜色
        wordPhoneticView.textColor = textColor
        scrollingMeaningView.textColor = textColor.withAlphaComponent(0.9)
    }
    
    // MARK: - Public Methods
    
    func updateContent(word: String, phonetic: String, meaning: String) {
        self.wordText = word
        self.phoneticText = phonetic
        self.meaningText = meaning
        
        // 获取设置
        let settings = LLSettingsStore.shared.settings
        
        // 根据设置控制显示内容
        if settings.statusBarShowWord {
            wordPhoneticView.word = word
        } else {
            wordPhoneticView.word = ""
        }
        
        if settings.statusBarShowPhoneticSymbol {
            wordPhoneticView.phonetic = phonetic
        } else {
            wordPhoneticView.phonetic = ""
        }
        
        if settings.statusBarShowMeaning {
            scrollingMeaningView.text = meaning
        } else {
            scrollingMeaningView.text = ""
        }
        
        // 根据设置控制是否强制滚动
        scrollingMeaningView.forcedScroll = !settings.statusBarAutoScroll
        
        DispatchQueue.main.async {
            self.needsDisplay = true
            self.updateLayer()
        }
    }
}

// MARK: - NSMenuDelegate

extension LLStatusBarContentView: NSMenuDelegate {
    
    override func mouseDown(with event: NSEvent) {
        if let menu = self.menu {
            // 使用 menu 属性代替废弃的 popUpMenu 方法
            NSMenu.popUpContextMenu(menu, with: event, for: self)
        }
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        needsDisplay = true
        clicked = true
    }
    
    func menuDidClose(_ menu: NSMenu) {
        needsDisplay = true
        clicked = false
    }
}
