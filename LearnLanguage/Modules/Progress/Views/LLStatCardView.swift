//
//  LLStatCardView.swift
//  LearnLanguage
//
//  统计卡片视图

import AppKit

final class LLStatCardView: NSView {
    
    private let iconLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 20)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let numberLabel: NSTextField = {
        let label = NSTextField(labelWithString: "0")
        label.font = NSFont.systemFont(ofSize: 26, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.accentColor
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let descLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        label.maximumNumberOfLines = 2
        return label
    }()
    
    init(icon: String, description: String) {
        super.init(frame: .zero)
        iconLabel.stringValue = icon
        descLabel.stringValue = description
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
        addSubview(iconLabel)
        addSubview(numberLabel)
        addSubview(descLabel)
    }
    
    override func layout() {
        super.layout()
        let w = bounds.width
        guard w > 0 else { return }
        let iconH: CGFloat = 26
        let numH: CGFloat = 32
        let descH: CGFloat = 30
        let totalH = iconH + 6 + numH + 4 + descH
        let startY = (bounds.height - totalH) / 2
        iconLabel.frame   = NSRect(x: 0, y: startY, width: w, height: iconH)
        numberLabel.frame = NSRect(x: 0, y: startY + iconH + 6, width: w, height: numH)
        descLabel.frame   = NSRect(x: 4, y: startY + iconH + 6 + numH + 4, width: w - 8, height: descH)
    }
    
    func updateNumber(_ value: String) {
        numberLabel.stringValue = value
    }
}
