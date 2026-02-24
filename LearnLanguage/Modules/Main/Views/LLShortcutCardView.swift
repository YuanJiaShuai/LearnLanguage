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
                return LLAppearanceManager.shared.colors.accentColor
            case .wrongWords:
                return LLAppearanceManager.shared.colors.errorColor
            }
        }
        
        var iconColor: NSColor {
            switch self {
            case .wordList:
                return LLAppearanceManager.shared.colors.accentColor
            case .wrongWords:
                return LLAppearanceManager.shared.colors.errorColor
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
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private lazy var badgeLabel: NSTextField = {
        let label = NSTextField(labelWithString: "0")
        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = .white
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.cornerRadius = 9
        label.layer?.backgroundColor = cardType.badgeColor.cgColor
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
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(badgeLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(36)
        }
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(badgeLabel.snp.leading).offset(-8)
        }
        
        badgeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(40)
            make.height.equalTo(20)
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
        titleLabel.stringValue = title
        badgeLabel.stringValue = badge
    }
}

