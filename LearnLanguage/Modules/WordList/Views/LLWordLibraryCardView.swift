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
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        layer?.backgroundColor = NSColor.white.cgColor
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 8
        addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview().offset(-16)
        }
        
        iconView.image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: nil)
        iconView.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        iconView.snp.makeConstraints { make in
            make.width.height.equalTo(14)
        }
        let nameStack = NSStackView()
        nameStack.orientation = .horizontal
        nameStack.spacing = 6
        nameStack.addArrangedSubview(iconView)
        nameLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        nameLabel.lineBreakMode = .byTruncatingTail
        nameStack.addArrangedSubview(nameLabel)
        
        // 学习中徽章
        learningBadge.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        learningBadge.textColor = .white
        learningBadge.alignment = .center
        learningBadge.wantsLayer = true
        learningBadge.layer?.cornerRadius = 3
        learningBadge.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        learningBadge.stringValue = "学习中"
        learningBadge.isHidden = true
        learningBadge.snp.makeConstraints { make in
            make.width.equalTo(50)
            make.height.equalTo(18)
        }
        nameStack.addArrangedSubview(learningBadge)
        
        stackView.addArrangedSubview(nameStack)
        
        countLabel.font = NSFont.systemFont(ofSize: 12)
        countLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        stackView.addArrangedSubview(countLabel)
        
        progressBar.wantsLayer = true
        progressBar.layer?.cornerRadius = 2
        progressBar.layer?.backgroundColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        progressBar.snp.makeConstraints { make in
            make.height.equalTo(4)
        }
        progressFill.wantsLayer = true
        progressFill.layer?.cornerRadius = 2
        progressFill.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        
        progressBar.addSubview(progressFill)
        progressFill.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            progressFillWidthConstraint = make.width.equalTo(0).constraint
        }
        
        stackView.addArrangedSubview(progressBar)
        
        // 鼠标事件
        let trackingArea = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
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
        let c = LLAppearanceManager.shared.colors
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        if isSelected {
            layer?.borderColor = c.accentColor.cgColor
            layer?.backgroundColor = c.accentLightBackground.cgColor
            layer?.borderWidth = 2
            iconView.image = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: nil)
            iconView.contentTintColor = c.accentColor
        } else {
            layer?.borderColor = c.borderColor.cgColor
            layer?.backgroundColor = NSColor.white.cgColor
            layer?.borderWidth = 1
            iconView.image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: nil)
            iconView.contentTintColor = c.accentColor
        }
        CATransaction.commit()
    }
    
    override func mouseDown(with event: NSEvent) {
        if let data = data {
            onClicked?(data)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if !isSelected {
            layer?.borderColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if !isSelected {
            layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        }
    }
    
    private func updateLearningBadge() {
        learningBadge.isHidden = !isCurrentLearning
    }
}
