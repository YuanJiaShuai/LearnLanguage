//
//  LLWrongRecordItemView.swift
//  LearnLanguage
//
//  错题记录项视图

import AppKit
import SnapKit

final class LLWrongRecordItemView: NSView {
    
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
    
    private let tagLabel: NSTextField = {
        let label = NSTextField(labelWithString: "需复习")
        label.font = NSFont.systemFont(ofSize: 10)
        label.textColor = .white
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = true
        label.backgroundColor = NSColor(srgbRed: 1.0, green: 0.27, blue: 0.23, alpha: 1)
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.cornerRadius = 4
        return label
    }()
    
    private let meanLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var markButton: NSButton = {
        let button = NSButton(title: "✓", target: self, action: #selector(markButtonClicked))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 16)
        button.contentTintColor = NSColor.systemGreen
        button.toolTip = "标记为已掌握"
        return button
    }()
    
    private lazy var reviewButton: NSButton = {
        let button = NSButton(title: "🔄", target: self, action: #selector(reviewButtonClicked))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 14)
        button.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        button.toolTip = "立即复习"
        return button
    }()
    
    private let separator: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.91, alpha: 1).cgColor
        return view
    }()
    
    // MARK: - Properties
    
    private let wordId: String
    
    // MARK: - Callbacks
    
    var onMarkAsKnown: ((String) -> Void)?
    var onReview: ((String) -> Void)?
    
    // MARK: - Initialization
    
    init(wordId: String, wordText: String, wordMean: String, showBorder: Bool) {
        self.wordId = wordId
        super.init(frame: .zero)
        
        wordLabel.stringValue = wordText
        meanLabel.stringValue = wordMean
        
        setupUI(showBorder: showBorder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI(showBorder: Bool) {
        wantsLayer = true
        
        // 左侧容器
        let leftContainer = NSView()
        leftContainer.wantsLayer = true
        addSubview(leftContainer)
        leftContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(-100)
        }
        
        // 单词和标签容器
        let wordContainer = NSView()
        wordContainer.wantsLayer = true
        leftContainer.addSubview(wordContainer)
        wordContainer.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
        }
        
        wordContainer.addSubview(wordLabel)
        wordLabel.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        wordContainer.addSubview(tagLabel)
        tagLabel.snp.makeConstraints { make in
            make.leading.equalTo(wordLabel.snp.trailing).offset(8)
            make.centerY.equalTo(wordLabel)
            make.trailing.equalToSuperview()
            make.width.greaterThanOrEqualTo(40)
            make.height.equalTo(18)
        }
        
        leftContainer.addSubview(meanLabel)
        meanLabel.snp.makeConstraints { make in
            make.leading.bottom.trailing.equalToSuperview()
            make.top.equalTo(wordContainer.snp.bottom).offset(2)
        }
        
        // 右侧操作按钮容器
        let actionContainer = NSView()
        actionContainer.wantsLayer = true
        addSubview(actionContainer)
        actionContainer.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
        
        actionContainer.addSubview(markButton)
        markButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        actionContainer.addSubview(reviewButton)
        reviewButton.snp.makeConstraints { make in
            make.leading.equalTo(markButton.snp.trailing).offset(12)
            make.trailing.top.bottom.equalToSuperview()
            make.width.height.equalTo(24)
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
    
    // MARK: - Actions
    
    @objc private func markButtonClicked() {
        onMarkAsKnown?(wordId)
    }
    
    @objc private func reviewButtonClicked() {
        onReview?(wordId)
    }
}

