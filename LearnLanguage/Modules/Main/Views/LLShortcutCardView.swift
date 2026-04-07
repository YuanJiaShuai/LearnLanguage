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
                return NSImage(systemSymbolName: "book.closed.fill", accessibilityDescription: nil)
            case .wrongWords:
                return NSImage(systemSymbolName: "exclamationmark.circle.fill", accessibilityDescription: nil)
            }
        }
        
        var placeholderTitle: String {
            switch self {
            case .wordList: return NSLocalizedString("No Word List", comment: "No word list placeholder")
            case .wrongWords: return NSLocalizedString("Today's Review", comment: "Today's review section title")
            }
        }
        
        var badgeBackgroundColor: NSColor {
            switch self {
            case .wordList:
                return LLAppearanceManager.shared.colors.accentLightBackground
            case .wrongWords:
                return LLAppearanceManager.shared.colors.errorContainer
            }
        }
        
        var badgeTextColor: NSColor {
            switch self {
            case .wordList:
                return LLAppearanceManager.shared.colors.accentColor
            case .wrongWords:
                return LLAppearanceManager.shared.colors.errorText
            }
        }
        
        var iconColor: NSColor {
            switch self {
            case .wordList:
                return LLAppearanceManager.shared.colors.secondaryText
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
        view.layer?.cornerRadius = 10
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.surfaceContainerLow.withAlphaComponent(0.92).cgColor
        return view
    }()
    
    private lazy var iconView: NSImageView = {
        let imageView = NSImageView()
        if let image = cardType.icon {
            image.isTemplate = true
            image.size = NSSize(width: 18, height: 18)
            imageView.image = image
        }
        imageView.contentTintColor = cardType.iconColor
        imageView.imageScaling = .scaleProportionallyDown
        return imageView
    }()
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: cardType.placeholderTitle)
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.lineBreakMode = .byTruncatingTail
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var badgeLabel: NSTextField = {
        let label = NSTextField(labelWithString: "0")
        label.font = NSFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = cardType.badgeTextColor
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.wantsLayer = true
        label.layer?.cornerRadius = 5
        label.layer?.backgroundColor = cardType.badgeBackgroundColor.cgColor
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
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(badgeLabel)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(38)
        }
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(badgeLabel.snp.leading).offset(-8)
        }
        
        badgeLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(34)
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
