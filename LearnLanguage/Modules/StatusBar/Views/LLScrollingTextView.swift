//
//  LLScrollingTextView.swift
//  LearnLanguage
//
//  滚动文本视图 - 跑马灯效果（参考 QMUI 实现）
//

import AppKit

final class LLScrollingTextView: NSView {
    
    // MARK: - Properties
    
    var text: String = "" {
        didSet {
            offsetX = 0
            textSize = calculateTextSize()
            checkIfShouldShowGradientLayer()
            needsDisplay = true
            // 不在这里设置 isPaused，因为此时 bounds 可能还是 (0,0,0,0)
            // 会在 layout() 中根据实际 bounds 来设置
        }
    }
    
    var textColor: NSColor = .white {
        didSet {
            needsDisplay = true
        }
    }
    
    var font: NSFont = .systemFont(ofSize: 12) {
        didSet {
            textSize = calculateTextSize()
            isPaused = !shouldPlayDisplayLink()
            needsDisplay = true
        }
    }
    
    /// 控制滚动的速度，默认为 0.5pt/帧
    var speed: CGFloat = 0.5
    
    /// 文字滚动到边缘时的停顿时长，默认为 2.5 秒
    var pauseDurationWhenMoveToEdge: TimeInterval = 2.5
    
    /// 首尾连接的文字之间的间距，默认为 40pt
    var spacingBetweenHeadToTail: CGFloat = 40
    
    /// 是否在边缘显示渐变遮罩，默认为 false
    var shouldFadeAtEdge: Bool = false {
        didSet {
            checkIfShouldShowGradientLayer()
            needsLayout = true
        }
    }
    
    /// 渐变区域的百分比，默认为 0.2（20%）
    var fadeWidthPercent: CGFloat = 0.2 {
        didSet {
            fadeEndPercent = fadeWidthPercent
        }
    }
    
    /// 当文字不足视图宽度时，是否强制滚动，默认为 false
    var forcedScroll: Bool = false {
        didSet {
            isPaused = !shouldPlayDisplayLink()
        }
    }
    
    // Private
    private var displayLink: Timer?
    private var offsetX: CGFloat = 0
    private var textSize: CGSize = .zero
    private var isFirstDisplay: Bool = true
    private var fadeLayer: CAGradientLayer?
    private var prevBounds: CGRect = .zero
    private var isPaused: Bool = true
    
    private var fadeStartPercent: CGFloat = 0
    private var fadeEndPercent: CGFloat = 0.2
    
    /// 重复绘制次数，用于首尾连接
    private let textRepeatCount: Int = 2
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // MARK: - Lifecycle
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if window != nil {
            displayLink = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
                self?.handleDisplayLink()
            }
            RunLoop.current.add(displayLink!, forMode: .common)
        } else {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        // 需要手动触发一下 setter
        let currentText = text
        text = currentText
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // 绘制背景色（如果设置了）
        if let bgColor = layer?.backgroundColor {
            NSColor(cgColor: bgColor)?.setFill()
            NSBezierPath(rect: bounds).fill()
        }
        
        guard !text.isEmpty else { return }
        
        // 设置裁剪区域，防止文本超出边界
        NSGraphicsContext.saveGraphicsState()
        NSBezierPath(rect: bounds).addClip()
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        // 计算初始 X 位置（左对齐）
        var textInitialX: CGFloat = 0
        // 如果文本宽度小于视图宽度，保持左对齐（不居中）
        
        // 计算垂直居中位置
        let y = (bounds.height - textSize.height) / 2
        
        // 重复绘制文本以实现首尾连接
        let repeatCount = textRepeatCountConsiderTextWidth
        for i in 0..<repeatCount {
            let x = offsetX + CGFloat(i) * (textSize.width + spacingBetweenHeadToTail) + textInitialX
            attributedString.draw(at: NSPoint(x: x, y: y))
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    // MARK: - Layout
    
    override func layout() {
        super.layout()
        
        if let fadeLayer = fadeLayer {
            fadeLayer.frame = bounds
        }
        
        if !prevBounds.size.equalTo(bounds.size) {
            offsetX = 0
            isPaused = !shouldPlayDisplayLink()
            prevBounds = bounds
            checkIfShouldShowGradientLayer()
        }
    }
    
    // MARK: - Private Methods
    
    private func calculateTextSize() -> CGSize {
        guard !text.isEmpty else { return .zero }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        return attributedString.boundingRect(with: NSSize(width: CGFloat.greatestFiniteMagnitude, height: 100), options: .usesLineFragmentOrigin).size
    }
    
    private var textRepeatCountConsiderTextWidth: Int {
        if !forcedScroll && textSize.width < bounds.width {
            return 1
        }
        return textRepeatCount
    }
    
    private func shouldPlayDisplayLink() -> Bool {
        // forcedScroll 为 true 时，才允许滚动（当文本超长时）
        // forcedScroll 为 false 时，永远不滚动
        let result = window != nil && bounds.width > 0 && forcedScroll && textSize.width > bounds.width
        return result
    }
    
    private func handleDisplayLink() {
        guard shouldPlayDisplayLink() else { return }
        
        // 如果处于暂停状态，不更新
        if isPaused {
            return
        }
        
        // 如果 offsetX 为 0，说明刚开始或刚重置
        if offsetX == 0 {
            isPaused = true
            needsDisplay = true
            
            let delay = (isFirstDisplay || textRepeatCount <= 1) ? pauseDurationWhenMoveToEdge : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                if self.shouldPlayDisplayLink() {
                    self.isPaused = false
                    self.offsetX -= self.speed
                }
            }
            
            if delay > 0 && textRepeatCount > 1 {
                isFirstDisplay = false
            }
            
            return
        }
        
        // 更新偏移
        offsetX -= speed
        needsDisplay = true
        
        // 检查是否滚动到末尾
        if -offsetX >= textSize.width + (textRepeatCountConsiderTextWidth > 1 ? spacingBetweenHeadToTail : 0) {
            isPaused = true
            let delay = textRepeatCount > 1 ? pauseDurationWhenMoveToEdge : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                self.offsetX = 0
                self.isPaused = false
            }
        }
    }
    
    private func checkIfShouldShowGradientLayer() {
        let shouldShowFadeLayer = window != nil && shouldFadeAtEdge && bounds.width > 0 && textSize.width > bounds.width
        
        if shouldShowFadeLayer {
            if fadeLayer == nil {
                fadeLayer = CAGradientLayer()
                fadeLayer?.locations = [
                    NSNumber(value: fadeStartPercent),
                    NSNumber(value: fadeEndPercent),
                    NSNumber(value: 1 - fadeEndPercent),
                    NSNumber(value: 1 - fadeStartPercent)
                ]
                fadeLayer?.startPoint = CGPoint(x: 0, y: 0.5)
                fadeLayer?.endPoint = CGPoint(x: 1, y: 0.5)
                fadeLayer?.colors = [
                    NSColor.white.withAlphaComponent(0).cgColor,
                    NSColor.white.withAlphaComponent(1).cgColor,
                    NSColor.white.withAlphaComponent(1).cgColor,
                    NSColor.white.withAlphaComponent(0).cgColor
                ]
                layer?.mask = fadeLayer
            }
            fadeLayer?.frame = bounds
            needsLayout = true
        } else {
            if layer?.mask == fadeLayer {
                layer?.mask = nil
            }
            fadeLayer = nil
        }
    }
}

