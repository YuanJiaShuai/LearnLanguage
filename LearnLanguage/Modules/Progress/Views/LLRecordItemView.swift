//
//  LLRecordItemView.swift
//  LearnLanguage
//
//  学习记录项视图

import AppKit

final class LLRecordItemView: NSView {
    
    private let wordLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private let timeLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private let separator: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.91, alpha: 1).cgColor
        return view
    }()
    
    private let showBorder: Bool
    
    init(wordText: String, feedbackIcon: String, time: Date, showBorder: Bool) {
        self.showBorder = showBorder
        super.init(frame: .zero)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        wordLabel.stringValue = "\(wordText) \(feedbackIcon)"
        timeLabel.stringValue = NSLocalizedString("Learning Time", comment: "") + timeFormatter.string(from: time)
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        wantsLayer = true
        addSubview(wordLabel)
        addSubview(timeLabel)
        if showBorder {
            addSubview(separator)
        }
    }
    
    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }
        
        wordLabel.frame = NSRect(x: 12, y: h / 2, width: w - 24, height: 18)
        timeLabel.frame = NSRect(x: 12, y: h / 2 - 18, width: w - 24, height: 16)
        if showBorder {
            separator.frame = NSRect(x: 12, y: 0, width: w - 12, height: 1)
        }
    }
}
