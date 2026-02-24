//
//  LLWordCellView.swift
//  LearnLanguage
//
//  词库详情页面 - 单词列表 Cell 视图

import AppKit
import SnapKit

final class LLWordCellView: NSView {
    
    private let wordLabel = NSTextField(labelWithString: "")
    private let phoneticLabel = NSTextField(labelWithString: "")
    private let meaningLabel = NSTextField(labelWithString: "")
    private let usButton = NSButton()
    private let ukButton = NSButton()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 单词标签
        wordLabel.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        wordLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        wordLabel.isEditable = false
        wordLabel.isBezeled = false
        wordLabel.drawsBackground = false
        
        // 音标标签
        phoneticLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        phoneticLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        phoneticLabel.isEditable = false
        phoneticLabel.isBezeled = false
        phoneticLabel.drawsBackground = false
        
        // 释义标签
        meaningLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        meaningLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        meaningLabel.isEditable = false
        meaningLabel.isBezeled = false
        meaningLabel.drawsBackground = false
        meaningLabel.lineBreakMode = .byTruncatingTail
        
        // 美式发音按钮
        usButton.title = "🇺🇸 美式"
        usButton.bezelStyle = .rounded
        usButton.controlSize = .small
        usButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        
        // 英式发音按钮
        ukButton.title = "🇬🇧 英式"
        ukButton.bezelStyle = .rounded
        ukButton.controlSize = .small
        ukButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        
        // 添加到视图
        addSubview(wordLabel)
        addSubview(phoneticLabel)
        addSubview(meaningLabel)
        addSubview(usButton)
        addSubview(ukButton)
        
        // 布局
        wordLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.top.equalToSuperview().offset(8)
            make.width.equalTo(150)
        }
        
        phoneticLabel.snp.makeConstraints { make in
            make.left.equalTo(wordLabel.snp.right).offset(12)
            make.centerY.equalTo(wordLabel)
            make.width.equalTo(120)
        }
        
        meaningLabel.snp.makeConstraints { make in
            make.left.equalTo(phoneticLabel.snp.right).offset(12)
            make.centerY.equalTo(wordLabel)
            make.right.equalTo(usButton.snp.left).offset(-12)
        }
        
        usButton.snp.makeConstraints { make in
            make.right.equalTo(ukButton.snp.left).offset(-8)
            make.centerY.equalTo(wordLabel)
            make.width.equalTo(70)
            make.height.equalTo(24)
        }
        
        ukButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalTo(wordLabel)
            make.width.equalTo(70)
            make.height.equalTo(24)
        }
    }
    
    func configure(with word: LLDBWord, row: Int, delegate: LLWordListDetailViewController) {
        wordLabel.stringValue = word.word
        
        // 显示音标（优先美式，其次英式）
        let phonetic = word.usPhonetic ?? word.ukPhonetic ?? ""
        phoneticLabel.stringValue = phonetic.isEmpty ? "-" : phonetic
        
        meaningLabel.stringValue = word.translation
        
        // 设置按钮 tag 和 action
        usButton.tag = row
        ukButton.tag = row
        usButton.target = delegate
        ukButton.target = delegate
        usButton.action = #selector(delegate.didClickPlayUS(_:))
        ukButton.action = #selector(delegate.didClickPlayUK(_:))
        
        // 根据是否有音标来启用/禁用按钮
        usButton.isEnabled = word.usPhonetic != nil && !word.usPhonetic!.isEmpty
        ukButton.isEnabled = word.ukPhonetic != nil && !word.ukPhonetic!.isEmpty
    }
}

