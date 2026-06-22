//
//  LLRecordItemView.swift
//  LearnLanguage
//
//  学习记录项视图

import AppKit
import SnapKit

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

        wordLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview().offset(-9)
            make.height.equalTo(18)
        }

        timeLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(wordLabel)
            make.top.equalTo(wordLabel.snp.bottom)
            make.height.equalTo(16)
        }

        if showBorder {
            separator.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(12)
                make.trailing.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
        }
    }
}
