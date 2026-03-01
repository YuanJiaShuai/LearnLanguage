//
//  LLWordLibraryCardView.swift
//  LearnLanguage
//
//  单个词库卡片视图，支持选中态和进度展示
//

import AppKit
import SnapKit

final class LLWordLibraryCardView: NSView {
    
    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "词库名称")
    private let countLabel = NSTextField(labelWithString: "0/1000")
    private let progressBar = NSView()
    private let progressFill = NSView()
    private let learningBadge = NSTextField(labelWithString: "")
    private var progressFillWidthConstraint: Constraint?
    
    var data: WordList? {
        didSet { updateUI() }
    }
    
    var learnedCount: Int = 0 {
        didSet { updateUI() }
    }
    
    var isSelected: Bool = false {
        didSet { updateSelection() }
    }
    
    var isCurrentLearning: Bool = false {
        didSet { updateLearningBadge() }
    }
    
    var onClicked: ((WordList) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.3).cgColor
        layer?.backgroundColor = NSColor.white.cgColor
        
        // 图标和标题容器
        let headerStack = NSStackView()
        headerStack.orientation = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .centerY
        addSubview(headerStack)
        
        headerStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        // 图标
        iconView.image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: nil)
        iconView.contentTintColor = NSColor.systemBlue
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(18)
        }
        headerStack.addArrangedSubview(iconView)
        
        // 标题
        nameLabel.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        nameLabel.lineBreakMode = .byTruncatingTail
        headerStack.addArrangedSubview(nameLabel)
        
        // 学习中徽章
        learningBadge.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        learningBadge.textColor = .white
        learningBadge.alignment = .center
        learningBadge.wantsLayer = true
        learningBadge.layer?.cornerRadius = 9
        learningBadge.layer?.backgroundColor = NSColor.systemBlue.cgColor
        learningBadge.stringValue = "学习中"
        learningBadge.isHidden = true
        learningBadge.snp.makeConstraints { make in
            make.width.equalTo(56)
            make.height.equalTo(18)
        }
        headerStack.addArrangedSubview(learningBadge)
        
        // 进度文字
        countLabel.font = NSFont.systemFont(ofSize: 13)
        countLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        // 进度条
        progressBar.wantsLayer = true
        progressBar.layer?.cornerRadius = 1.5
        progressBar.layer?.backgroundColor = NSColor.systemGray.withAlphaComponent(0.15).cgColor
        addSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(3)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        progressFill.wantsLayer = true
        progressFill.layer?.cornerRadius = 1.5
        progressFill.layer?.backgroundColor = NSColor.systemBlue.cgColor
        progressBar.addSubview(progressFill)
        progressFill.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            progressFillWidthConstraint = make.width.equalTo(0).constraint
        }
        
        // 鼠标事件
        let trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    private func updateUI() {
        guard let data = data else { return }
        
        nameLabel.stringValue = data.name
        countLabel.stringValue = "\(learnedCount)/\(data.entryCount) 词已学习"
        
        let progress = CGFloat(learnedCount) / CGFloat(max(1, data.entryCount))
        let width = progressBar.bounds.width * progress
        progressFillWidthConstraint?.update(offset: width)
    }
    
    private func updateSelection() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        if isSelected {
            layer?.borderColor = NSColor.systemBlue.cgColor
            layer?.borderWidth = 2
            layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.05).cgColor
            iconView.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
            iconView.contentTintColor = NSColor.systemBlue
        } else {
            layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.3).cgColor
            layer?.borderWidth = 1
            layer?.backgroundColor = NSColor.white.cgColor
            iconView.image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: nil)
            iconView.contentTintColor = NSColor.systemBlue
        }
        CATransaction.commit()
    }
    
    override func mouseDown(with event: NSEvent) {
        if let data = data {
            onClicked?(data)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if !isSelected && !isCurrentLearning {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                layer?.borderWidth = 1
                layer?.borderColor = NSColor.systemBlue.cgColor
                layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.03).cgColor
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if !isSelected {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                // 如果是正在学习的词库，保持边框为 2 和浅蓝色背景
                if isCurrentLearning {
                    layer?.borderWidth = 2
                    layer?.borderColor = NSColor.systemBlue.cgColor
                    layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.05).cgColor
                } else {
                    layer?.borderWidth = 1
                    layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.3).cgColor
                    layer?.backgroundColor = NSColor.white.cgColor
                }
            }
        }
    }
    
    private func updateLearningBadge() {
        learningBadge.isHidden = true  // 始终隐藏徽章
        
        // 如果是正在学习的词库，设置边框为 2 和浅蓝色背景
        if isCurrentLearning && !isSelected {
            layer?.borderWidth = 2
            layer?.borderColor = NSColor.systemBlue.cgColor
            layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.05).cgColor
        } else if !isSelected {
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.3).cgColor
            layer?.backgroundColor = NSColor.white.cgColor
        }
    }
}
