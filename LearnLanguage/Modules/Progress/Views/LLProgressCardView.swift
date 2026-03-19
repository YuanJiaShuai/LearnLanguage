//
//  LLProgressCardView.swift
//  LearnLanguage
//
//  进度卡片视图

import AppKit

final class LLProgressCardView: NSView {
    
    private let iconLabel: NSTextField = {
        let label = NSTextField(labelWithString: "✅")
        label.font = NSFont.systemFont(ofSize: 20)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let numberLabel: NSTextField = {
        let label = NSTextField(labelWithString: "0/0")
        label.font = NSFont.systemFont(ofSize: 26, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.accentColor
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let descLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Today's Progress", comment: ""))
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let progressBar: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.91, alpha: 1).cgColor
        view.layer?.cornerRadius = 3
        return view
    }()
    
    private let progressFill: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        view.layer?.cornerRadius = 3
        return view
    }()
    
    private var progressRatio: CGFloat = 0
    
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
        addSubview(iconLabel)
        addSubview(numberLabel)
        addSubview(descLabel)
        addSubview(progressBar)
        progressBar.addSubview(progressFill)
    }
    
    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }
        
        let iconH: CGFloat = 26
        let numH: CGFloat = 32
        let descH: CGFloat = 18
        let barH: CGFloat = 6
        let totalH = iconH + 6 + numH + 4 + descH + 8 + barH
        let startY = (h - totalH) / 2
        
        iconLabel.frame   = NSRect(x: 0, y: startY, width: w, height: iconH)
        numberLabel.frame = NSRect(x: 0, y: startY + iconH + 6, width: w, height: numH)
        descLabel.frame   = NSRect(x: 4, y: startY + iconH + 6 + numH + 4, width: w - 8, height: descH)
        
        let barY = startY + iconH + 6 + numH + 4 + descH + 8
        progressBar.frame = NSRect(x: 16, y: barY, width: w - 32, height: barH)
        progressFill.frame = NSRect(x: 0, y: 0, width: (w - 32) * progressRatio, height: barH)
    }
    
    func updateProgress(current: Int, total: Int) {
        numberLabel.stringValue = "\(current)/\(total)"
        progressRatio = total > 0 ? min(1.0, CGFloat(current) / CGFloat(total)) : 0
        needsLayout = true
    }
}
