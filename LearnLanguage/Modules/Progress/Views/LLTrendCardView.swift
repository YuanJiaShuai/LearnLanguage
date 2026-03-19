//
//  LLTrendCardView.swift
//  LearnLanguage
//
//  学习趋势图表卡片视图

import AppKit

final class LLTrendCardView: NSView {
    
    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Learning Statistics", comment: ""))
        label.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private let chartPlaceholder: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(srgbRed: 0.94, green: 0.94, blue: 0.96, alpha: 1).cgColor
        view.layer?.cornerRadius = 8
        return view
    }()
    
    private let placeholderText: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Trend Chart Placeholder", comment: ""))
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(srgbRed: 0.98, green: 0.98, blue: 0.97, alpha: 1).cgColor
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.91, alpha: 1).cgColor
        addSubview(titleLabel)
        addSubview(chartPlaceholder)
        chartPlaceholder.addSubview(placeholderText)
    }
    
    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }
        
        titleLabel.frame = NSRect(x: 20, y: 20, width: w - 40, height: 22)
        let chartY: CGFloat = 20 + 22 + 12
        let chartH = h - chartY - 16
        chartPlaceholder.frame = NSRect(x: 16, y: chartY, width: w - 32, height: chartH)
        
        let ptW = placeholderText.intrinsicContentSize.width
        let ptH: CGFloat = 20
        placeholderText.frame = NSRect(
            x: (chartPlaceholder.bounds.width - ptW) / 2,
            y: (chartPlaceholder.bounds.height - ptH) / 2,
            width: ptW, height: ptH
        )
    }
}
