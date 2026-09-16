//
//  LLStatusBarFeedbackView.swift
//  LearnLanguage
//
//  状态栏反馈视图 - 四个图标按钮（显示 / 认识 / 模糊 / 不认识）
//

import AppKit

final class LLStatusBarFeedbackView: NSView {
    
    // MARK: - Properties
    
    private let iconSize: CGFloat = 14
    private let spacing: CGFloat = 2
    private var images: [NSImage] = []
    private var hoverIndex: Int = -1
    
    /// 反馈回调
    var onFeedback: ((LLWordFeedback) -> Void)?
    
    /// 显示按钮回调
    var onShow: (() -> Void)?
    
    // MARK: - Initialization
    
    override var intrinsicContentSize: NSSize {
        let w = CGFloat(4) * iconSize + spacing * 3
        return NSSize(width: w, height: NSStatusBar.system.thickness)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupImages()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupImages() {
        // 按顺序：显示、认识、模糊、不认识
        let imageNames = ["feedback_show", "feedback_know", "feedback_vague", "feedback_unknown"]
        
        images = imageNames.compactMap { name in
            if let image = NSImage(named: name) {
                LLLogger.debug("✅ 成功加载图片: \(name)")
                image.isTemplate = true
                return image
            } else {
                LLLogger.warn("⚠️ 加载图片失败: \(name)")
                return nil
            }
        }
        
        // 如果自定义图片加载失败，使用系统图标作为后备
        if images.count < 4 {
            LLLogger.warn("⚠️ 自定义图片加载不完整，使用系统图标作为后备")
            images = [
                NSImage(systemSymbolName: "eye.fill", accessibilityDescription: NSLocalizedString("Show", comment: "Show button")),
                NSImage(systemSymbolName: "hand.thumbsup.fill", accessibilityDescription: NSLocalizedString("Know", comment: "Know button")),
                NSImage(systemSymbolName: "questionmark.circle.fill", accessibilityDescription: NSLocalizedString("Unclear", comment: "Unclear button")),
                NSImage(systemSymbolName: "hand.thumbsdown.fill", accessibilityDescription: NSLocalizedString("Unknown", comment: "Unknown button"))
            ].compactMap { $0 }
            images.forEach { $0.isTemplate = true }
        } else {
            LLLogger.debug("✅ 所有自定义图片加载成功")
        }
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        for (i, img) in images.enumerated() {
            let x = CGFloat(i) * (iconSize + spacing) + spacing * 0.5
            let y = (bounds.height - iconSize) / 2
            let rect = NSRect(x: x, y: y, width: iconSize, height: iconSize)
            
            // 悬停时降低透明度
            let alpha: CGFloat = hoverIndex == i ? 0.8 : 1.0
            img.draw(in: rect, from: .zero, operation: .sourceOver, fraction: alpha)
        }
    }
    
    // MARK: - Mouse Events
    
    override func mouseDown(with event: NSEvent) {
        let loc = currentPointerLocation() ?? convert(event.locationInWindow, from: nil)
        let i = index(at: loc)
        
        if i == 0 {
            // 第一个按钮：显示
            onShow?()
        } else if i == 1 {
            // 第二个按钮：认识
            onFeedback?(.know)
        } else if i == 2 {
            // 第三个按钮：模糊
            onFeedback?(.unclear)
        } else if i == 3 {
            // 第四个按钮：不认识
            onFeedback?(.unknown)
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        updateHover(with: event)
    }
    
    override func mouseExited(with event: NSEvent) {
        hoverIndex = -1
        needsDisplay = true
    }
    
    override func mouseMoved(with event: NSEvent) {
        updateHover(with: event)
    }
    
    // MARK: - Helper Methods
    
    private func index(at location: NSPoint) -> Int {
        for i in 0..<4 {
            let x = CGFloat(i) * (iconSize + spacing) + spacing * 0.5
            if location.x >= x && location.x < x + iconSize {
                return i
            }
        }
        return -1
    }
    
    private func updateHover(with event: NSEvent) {
        let loc = currentPointerLocation() ?? convert(event.locationInWindow, from: nil)
        let newHover = index(at: loc)
        
        if newHover != hoverIndex {
            hoverIndex = newHover
            needsDisplay = true
        }
    }

    private func currentPointerLocation() -> NSPoint? {
        guard let window else { return nil }
        let pointInWindow = window.convertFromScreen(
            NSRect(origin: NSEvent.mouseLocation, size: .zero)
        ).origin
        let point = convert(pointInWindow, from: nil)
        return bounds.contains(point) ? point : nil
    }
}
