//
//  LLRecordItemView.swift
//  LearnLanguage
//
//  学习记录项视图

import AppKit
import SnapKit

final class LLRecordItemView: NSView {
    
    // MARK: - UI Components
    
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
    
    // MARK: - Initialization
    
    init(wordText: String, feedbackIcon: String, time: Date, showBorder: Bool) {
        super.init(frame: .zero)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: time)
        
        wordLabel.stringValue = "\(wordText) \(feedbackIcon)"
        timeLabel.stringValue = "学习时间：\(timeString)"
        
        setupUI(showBorder: showBorder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI(showBorder: Bool) {
        wantsLayer = true
        
        // 左侧容器
        let leftStack = NSView()
        leftStack.wantsLayer = true
        addSubview(leftStack)
        leftStack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
        }
        
        leftStack.addSubview(wordLabel)
        wordLabel.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }
        
        leftStack.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(wordLabel.snp.bottom).offset(2)
        }
        
        // 分隔线
        if showBorder {
            addSubview(separator)
            separator.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(1)
            }
        }
    }
}

