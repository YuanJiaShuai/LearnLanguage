//
//  LLWordPhoneticView.swift
//  LearnLanguage
//
//  单词和音标显示视图 - 两行布局
//

import AppKit
import SnapKit

final class LLWordPhoneticView: NSView {
    
    // MARK: - Properties
    
    var word: String = "" {
        didSet {
            wordLabel.stringValue = word
            invalidateIntrinsicContentSize()
        }
    }
    
    var phonetic: String = "" {
        didSet {
            phoneticLabel.stringValue = phonetic
            phoneticLabel.isHidden = phonetic.isEmpty
            invalidateIntrinsicContentSize()
        }
    }
    
    var textColor: NSColor = .white {
        didSet {
            wordLabel.textColor = textColor
            phoneticLabel.textColor = textColor.withAlphaComponent(0.8)
        }
    }
    
    // MARK: - UI Components
    
    private lazy var wordLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.lineBreakMode = .byClipping
        return label
    }()
    
    private lazy var phoneticLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.lineBreakMode = .byClipping
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        
        // 设置默认文本以便调试
        word = "Loading..."
        phonetic = ""
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(wordLabel)
        addSubview(phoneticLabel)
        
        // 单词在上方
        wordLabel.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
        }
        
        // 音标在下方
        phoneticLabel.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(wordLabel.snp.bottom).offset(2)
        }
    }
    
    // MARK: - Intrinsic Content Size
    
    override var intrinsicContentSize: NSSize {
        // 使用 NSAttributedString 计算文本实际宽度
        let wordAttributes: [NSAttributedString.Key: Any] = [
            .font: wordLabel.font ?? NSFont.systemFont(ofSize: 12, weight: .medium)
        ]
        let phoneticAttributes: [NSAttributedString.Key: Any] = [
            .font: phoneticLabel.font ?? NSFont.systemFont(ofSize: 12)
        ]
        
        let wordSize = (word as NSString).size(withAttributes: wordAttributes)
        let phoneticSize = phonetic.isEmpty ? .zero : (phonetic as NSString).size(withAttributes: phoneticAttributes)
        
        let width = max(wordSize.width, phoneticSize.width)
        let height = wordSize.height + (phonetic.isEmpty ? 0 : 2 + phoneticSize.height)
        
        return NSSize(width: width, height: height)
    }
}

