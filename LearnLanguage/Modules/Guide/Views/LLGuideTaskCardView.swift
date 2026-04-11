import AppKit
import SnapKit

final class LLGuideTaskCardView: NSView {
    
    var onPrimaryAction: (() -> Void)?
    var onSecondaryAction: (() -> Void)?
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "开始你的第一轮学习")
        label.font = NSFont.inter(20, .bold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        return label
    }()
    
    private lazy var subtitleLabel: NSTextField = {
        let label = NSTextField(wrappingLabelWithString: "先选择一个词库开始学习；遇到不会的词，可以通过翻译加入生词本。")
        label.font = NSFont.inter(13, .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.76)
        label.maximumNumberOfLines = 2
        return label
    }()
    
    private lazy var accentPill: NSTextField = {
        let label = NSTextField(labelWithString: "首次引导")
        label.font = NSFont.inter(10, .bold)
        label.textColor = .white
        label.alignment = .center
        label.wantsLayer = true
        label.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        label.layer?.cornerRadius = 7
        return label
    }()
    
    private lazy var primaryButton: NSButton = {
        let button = NSButton(title: "打开词库", target: self, action: #selector(primaryTapped))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.wantsLayer = true
        button.font = NSFont.inter(13, .semiBold)
        button.contentTintColor = .white
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        button.layer?.cornerRadius = 10
        return button
    }()
    
    private lazy var secondaryButton: NSButton = {
        let button = NSButton(title: "打开生词本", target: self, action: #selector(secondaryTapped))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.wantsLayer = true
        button.font = NSFont.inter(13, .semiBold)
        button.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentLightBackground.cgColor
        button.layer?.cornerRadius = 10
        return button
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func configure(hasCurrentList: Bool, hasAnyWordList: Bool) {
        if hasCurrentList {
            isHidden = true
            return
        }
        
        isHidden = false
        titleLabel.stringValue = hasAnyWordList ? "先选一个词库开始学习" : "先创建你的第一个词库"
        subtitleLabel.stringValue = hasAnyWordList
            ? "进入任意词库即可开始学习；翻译时遇到不会的词，可以直接加入生词本。"
            : "你可以先创建词库，或者先通过翻译功能把不会的词加入生词本。"
        primaryButton.title = hasAnyWordList ? "打开第一个词库" : "新建词库"
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 20
        layer?.borderWidth = 1
        layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.6).cgColor
        layer?.backgroundColor = NSColor.white.cgColor
        layer?.shadowColor = NSColor.black.withAlphaComponent(0.05).cgColor
        layer?.shadowOpacity = 1
        layer?.shadowRadius = 14
        layer?.shadowOffset = CGSize(width: 0, height: -3)
        
        addSubview(accentPill)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(primaryButton)
        addSubview(secondaryButton)
        
        accentPill.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.left.equalToSuperview().offset(20)
            make.width.equalTo(64)
            make.height.equalTo(22)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(accentPill.snp.bottom).offset(14)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        primaryButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(18)
            make.left.equalToSuperview().offset(20)
            make.height.equalTo(38)
            make.bottom.equalToSuperview().offset(-18)
            make.width.greaterThanOrEqualTo(120)
        }
        
        secondaryButton.snp.makeConstraints { make in
            make.left.equalTo(primaryButton.snp.right).offset(10)
            make.centerY.equalTo(primaryButton)
            make.height.equalTo(38)
            make.width.greaterThanOrEqualTo(120)
        }
    }
    
    @objc private func primaryTapped() {
        onPrimaryAction?()
    }
    
    @objc private func secondaryTapped() {
        onSecondaryAction?()
    }
}
