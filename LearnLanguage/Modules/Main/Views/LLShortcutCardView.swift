//
//  LLShortcutCardView.swift
//  LearnLanguage
//
//  快捷入口卡片视图
//

import AppKit
import SnapKit

final class LLShortcutCardView: NSView {
    
    enum CardType {
        case wordList
        case wrongWords
        
        var icon: NSImage? {
            switch self {
            case .wordList:
                return NSImage(systemSymbolName: "book.fill", accessibilityDescription: nil)
            case .wrongWords:
                return NSImage(systemSymbolName: "exclamationmark.circle.fill", accessibilityDescription: nil)
            }
        }
        
        var placeholderTitle: String {
            switch self {
            case .wordList: return "暂无词库"
            case .wrongWords: return "未复习错题"
            }
        }
        
        var badgeColor: NSColor {
            switch self {
            case .wordList:
                return NSColor.systemBlue
            case .wrongWords:
                return NSColor.systemBlue
            }
        }
        
        var iconColor: NSColor {
            switch self {
            case .wordList:
                return NSColor.systemBlue
            case .wrongWords:
                return NSColor.systemBlue
            }
        }
    }
    
    private let cardType: CardType
    var onTap: (() -> Void)?
    
    // MARK: - UI Components
    
    private lazy var containerView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 6
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }()
    
    private lazy var iconView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = cardType.icon
        imageView.contentTintColor = cardType.iconColor
        return imageView
    }()
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: cardType.placeholderTitle)
        label.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.lineBreakMode = .byTruncatingTail
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var nameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.lineBreakMode = .byTruncatingTail
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var badgeLabel: NSTextField = {
        let label = NSTextField(labelWithString: "0")
        label.font = NSFont.systemFont(ofSize: 10, weight: .medium)
        label.textColor = .white
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.wantsLayer = true
        label.layer?.cornerRadius = 8
        label.layer?.backgroundColor = cardType.badgeColor.cgColor
        // 关键：设置垂直居中
        label.usesSingleLineMode = true
        label.cell?.usesSingleLineMode = true
        label.cell?.wraps = false
        label.cell?.isScrollable = false
        label.lineBreakMode = .byClipping
        return label
    }()
    
    // MARK: - Initialization
    
    init(type: CardType) {
        self.cardType = type
        super.init(frame: .zero)
        setupUI()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(containerView)
        
        // 顶部容器：标题 + 角标
        let topContainer = NSView()
        containerView.addSubview(topContainer)
        topContainer.addSubview(titleLabel)
        topContainer.addSubview(badgeLabel)
        
        // 底部：词库名称
        containerView.addSubview(nameLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(52)
        }
        
        topContainer.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(18)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        badgeLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(6)
            make.trailing.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(32)
            make.height.equalTo(16)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(topContainer.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    private func setupGesture() {
        let click = NSClickGestureRecognizer(target: self, action: #selector(handleTap))
        containerView.addGestureRecognizer(click)
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    // MARK: - Public Methods
    
    func updateContent(title: String, badge: String) {
        nameLabel.stringValue = title
        badgeLabel.stringValue = badge
    }
}

