//
//  LLStatusLearnIndicatorView.swift
//  LearnLanguage
//
//  学习进度指示器 - 4 个小方块垂直排布，根据 reviewCount 从下往上点亮
//

import AppKit

final class LLStatusLearnIndicatorView: NSView {
    
    // MARK: - Properties
    
    private let blockSize: CGFloat = 4
    private let blockSpacing: CGFloat = 2
    private let maxBlocks = 4
    
    private let activeColor = NSColor(red: 0.2, green: 0.8, blue: 0.4, alpha: 1.0)  // 绿色
    private let inactiveColor = NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)  // 灰色
    
    var reviewCount: Int = 0 {
        didSet {
            needsDisplay = true
        }
    }
    
    // MARK: - Initialization
    
    override var intrinsicContentSize: NSSize {
        let height = CGFloat(maxBlocks) * blockSize + CGFloat(maxBlocks - 1) * blockSpacing
        return NSSize(width: blockSize, height: height)
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let displayCount = min(reviewCount, maxBlocks)
        
        for i in 0..<maxBlocks {
            let y = bounds.height - CGFloat(i + 1) * (blockSize + blockSpacing)
            let rect = NSRect(x: 0, y: y, width: blockSize, height: blockSize)
            
            // 从下往上判断是否点亮
            let isActive = i < displayCount
            let color = isActive ? activeColor : inactiveColor
            
            color.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 1, yRadius: 1).fill()
        }
    }
}
