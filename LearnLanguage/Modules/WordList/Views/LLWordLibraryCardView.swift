import AppKit
import SnapKit

final class LLWordLibraryCardView: NSView {
    
    private let iconContainerView = NSView()
    private let iconView = NSImageView()
    private let categoryBadgeLabel = NSTextField(labelWithString: "")
    private let nameLabel = NSTextField(labelWithString: "词库名称")
    private let learnedCountLabel = NSTextField(labelWithString: "0")
    private let totalCountLabel = NSTextField(labelWithString: "/ 0 词")
    private let progressTitleLabel = NSTextField(labelWithString: NSLocalizedString("Learning Progress", comment: "Learning progress title"))
    private let progressPercentLabel = NSTextField(labelWithString: "0%")
    private let progressBar = NSView()
    private let progressFill = NSView()
    private var progressFillWidthConstraint: Constraint?
    private var tracking: NSTrackingArea?
    
    var data: WordList? {
        didSet { updateUI() }
    }
    
    var learnedCount: Int = 0 {
        didSet { updateUI() }
    }
    
    var isSelected: Bool = false {
        didSet { updateCardAppearance(animated: true) }
    }
    
    var isCurrentLearning: Bool = false {
        didSet { updateCardAppearance(animated: false) }
    }
    
    var onClicked: ((WordList) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking {
            removeTrackingArea(tracking)
        }
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        tracking = area
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.borderWidth = 1
        layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.4).cgColor
        layer?.backgroundColor = NSColor.white.cgColor
        layer?.shadowColor = NSColor.black.withAlphaComponent(0.06).cgColor
        layer?.shadowOpacity = 1
        layer?.shadowOffset = CGSize(width: 0, height: -2)
        layer?.shadowRadius = 10
        
        iconContainerView.wantsLayer = true
        iconContainerView.layer?.cornerRadius = 12
        iconContainerView.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.withAlphaComponent(0.1).cgColor
        addSubview(iconContainerView)
        
        iconView.image = NSImage(systemSymbolName: "translate", accessibilityDescription: nil)
        iconView.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        iconView.imageScaling = .scaleProportionallyDown
        iconContainerView.addSubview(iconView)
        
        categoryBadgeLabel.font = NSFont.inter(10, .semiBold)
        categoryBadgeLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.8)
        categoryBadgeLabel.alignment = .center
        categoryBadgeLabel.isBezeled = false
        categoryBadgeLabel.isEditable = false
        categoryBadgeLabel.drawsBackground = false
        categoryBadgeLabel.wantsLayer = true
        categoryBadgeLabel.layer?.cornerRadius = 6
        categoryBadgeLabel.layer?.backgroundColor = LLAppearanceManager.shared.colors.surfaceContainer.withAlphaComponent(0.85).cgColor
        addSubview(categoryBadgeLabel)
        
        nameLabel.font = NSFont.inter(20, .bold)
        nameLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.maximumNumberOfLines = 1
        addSubview(nameLabel)
        
        learnedCountLabel.font = NSFont.inter(28, .bold)
        learnedCountLabel.textColor = LLAppearanceManager.shared.colors.accentColor
        addSubview(learnedCountLabel)
        
        totalCountLabel.font = NSFont.inter(12, .medium)
        totalCountLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        addSubview(totalCountLabel)
        
        progressTitleLabel.font = NSFont.inter(11, .semiBold)
        progressTitleLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.6)
        addSubview(progressTitleLabel)
        
        progressPercentLabel.font = NSFont.inter(11, .semiBold)
        progressPercentLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.6)
        progressPercentLabel.alignment = .right
        addSubview(progressPercentLabel)
        
        progressBar.wantsLayer = true
        progressBar.layer?.cornerRadius = 3
        progressBar.layer?.backgroundColor = LLAppearanceManager.shared.colors.surfaceContainer.cgColor
        addSubview(progressBar)
        
        progressFill.wantsLayer = true
        progressFill.layer?.cornerRadius = 3
        progressFill.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        progressBar.addSubview(progressFill)
        
        iconContainerView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(24)
            make.width.height.equalTo(48)
        }
        
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        categoryBadgeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(22)
            make.width.greaterThanOrEqualTo(74)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainerView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
        }
        
        learnedCountLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(24)
        }
        
        totalCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(learnedCountLabel.snp.trailing).offset(4)
            make.bottom.equalTo(learnedCountLabel.snp.bottom).offset(-3)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
        }
        
        progressTitleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.bottom.equalTo(progressBar.snp.top).offset(-8)
        }
        
        progressPercentLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-24)
            make.centerY.equalTo(progressTitleLabel)
        }
        
        progressBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-24)
            make.height.equalTo(6)
        }
        
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            progressFillWidthConstraint = make.width.equalTo(0).constraint
        }
    }
    
    private func updateUI() {
        guard let data else { return }
        
        let totalCount = max(data.entryCount, data.totalWords ?? data.entryCount)
        let progress = totalCount > 0 ? CGFloat(learnedCount) / CGFloat(totalCount) : 0
        let percentText = String(format: "%.1f%%", progress * 100)
        
        nameLabel.stringValue = data.name
        categoryBadgeLabel.stringValue = data.category
        learnedCountLabel.stringValue = "\(learnedCount)"
        totalCountLabel.stringValue = "/ \(totalCount) \(NSLocalizedString("words", comment: "Words unit"))"
        progressPercentLabel.stringValue = percentText
        
        layoutSubtreeIfNeeded()
        let maxWidth = progressBar.bounds.width
        progressFillWidthConstraint?.update(offset: max(0, min(maxWidth, maxWidth * progress)))
    }
    
    private func updateCardAppearance(animated: Bool) {
        let changes = {
            if self.isSelected || self.isCurrentLearning {
                self.layer?.borderColor = LLAppearanceManager.shared.colors.accentColor.withAlphaComponent(0.28).cgColor
                self.layer?.backgroundColor = NSColor.white.cgColor
                self.layer?.shadowColor = NSColor.black.withAlphaComponent(0.08).cgColor
                self.layer?.shadowRadius = 16
                self.layer?.shadowOffset = CGSize(width: 0, height: -4)
            } else {
                self.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.4).cgColor
                self.layer?.backgroundColor = NSColor.white.cgColor
                self.layer?.shadowColor = NSColor.black.withAlphaComponent(0.06).cgColor
                self.layer?.shadowRadius = 10
                self.layer?.shadowOffset = CGSize(width: 0, height: -2)
            }
        }
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                changes()
            }
        } else {
            changes()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if let data {
            onClicked?(data)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if !isSelected {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                self.layer?.shadowColor = NSColor.black.withAlphaComponent(0.08).cgColor
                self.layer?.shadowRadius = 16
                self.layer?.shadowOffset = CGSize(width: 0, height: -4)
                self.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.22).cgColor
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if !isSelected {
            updateCardAppearance(animated: true)
        }
    }
}
