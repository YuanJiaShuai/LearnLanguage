import AppKit
import SnapKit

private final class LLVerticalCenterTextFieldCell: NSTextFieldCell {
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        var newRect = super.drawingRect(forBounds: rect)
        let textSize = cellSize(forBounds: rect)
        newRect.origin.y = rect.origin.y + (rect.height - textSize.height) / 2
        newRect.size.height = textSize.height
        return newRect
    }
}

final class LLWordLibraryCardView: NSView {
    enum LayoutMode { case grid, list }

    private let iconContainerView = NSView()
    private let iconView = NSImageView()
    private let categoryBadgeLabel = NSTextField(labelWithString: "")
    private let specialBadgeLabel = NSTextField(labelWithString: "")
    private let nameLabel = NSTextField(labelWithString: "词库名称")
    private let learnedCountLabel = NSTextField(labelWithString: "0")
    private let totalCountLabel = NSTextField(labelWithString: "/ 0 词")
    private let progressTitleLabel = NSTextField(labelWithString: NSLocalizedString("Learning Progress", comment: "Learning progress title"))
    private let progressPercentLabel = NSTextField(labelWithString: "0%")
    private let progressBar = NSView()
    private let progressFill = NSView()
    private var progressFillWidthConstraint: Constraint?
    private var tracking: NSTrackingArea?

    var data: WordList? { didSet { updateUI() } }
    var badgeTitle: String? { didSet { updateUI() } }
    var learnedCount: Int = 0 { didSet { updateUI() } }
    var layoutMode: LayoutMode = .grid { didSet { updateLayoutMode() } }
    var isSelected: Bool = false { didSet { updateCardAppearance(animated: true) } }
    var isCurrentLearning: Bool = false { didSet { updateCardAppearance(animated: false) } }
    var onClicked: ((WordList) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        updateLayoutMode()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect], owner: self, userInfo: nil)
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
        categoryBadgeLabel.cell = LLVerticalCenterTextFieldCell(textCell: "")
        categoryBadgeLabel.cell?.alignment = .center
        categoryBadgeLabel.cell?.usesSingleLineMode = true
        categoryBadgeLabel.cell?.wraps = false
        categoryBadgeLabel.lineBreakMode = .byTruncatingTail
        categoryBadgeLabel.wantsLayer = true
        categoryBadgeLabel.layer?.cornerRadius = 6
        categoryBadgeLabel.layer?.backgroundColor = LLAppearanceManager.shared.colors.surfaceContainer.withAlphaComponent(0.85).cgColor
        addSubview(categoryBadgeLabel)
        
        specialBadgeLabel.font = NSFont.inter(10, .bold)
        specialBadgeLabel.textColor = .white
        specialBadgeLabel.alignment = .center
        specialBadgeLabel.cell = LLVerticalCenterTextFieldCell(textCell: "")
        specialBadgeLabel.cell?.alignment = .center
        specialBadgeLabel.cell?.usesSingleLineMode = true
        specialBadgeLabel.cell?.wraps = false
        specialBadgeLabel.lineBreakMode = .byTruncatingTail
        specialBadgeLabel.wantsLayer = true
        specialBadgeLabel.layer?.cornerRadius = 6
        specialBadgeLabel.layer?.backgroundColor = NSColor.systemOrange.cgColor
        specialBadgeLabel.isHidden = true
        addSubview(specialBadgeLabel)

        nameLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.maximumNumberOfLines = 1
        addSubview(nameLabel)

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

        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            progressFillWidthConstraint = make.width.equalTo(0).constraint
        }
    }

    private func updateLayoutMode() {
        [iconContainerView, categoryBadgeLabel, specialBadgeLabel, nameLabel, learnedCountLabel, totalCountLabel, progressTitleLabel, progressPercentLabel, progressBar].forEach { $0.snp.removeConstraints() }

        switch layoutMode {
        case .grid:
            nameLabel.font = NSFont.inter(20, .bold)
            learnedCountLabel.font = NSFont.inter(28, .bold)

            iconContainerView.snp.makeConstraints { make in
                make.top.leading.equalToSuperview().offset(24)
                make.width.height.equalTo(48)
            }
            categoryBadgeLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(24)
                make.trailing.equalToSuperview().offset(-24)
                make.height.equalTo(22)
                make.width.greaterThanOrEqualTo(74)
            }
            specialBadgeLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(24)
                make.trailing.equalTo(categoryBadgeLabel.snp.leading).offset(-8)
                make.height.equalTo(22)
                make.width.greaterThanOrEqualTo(62)
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
        case .list:
            nameLabel.font = NSFont.inter(18, .bold)
            learnedCountLabel.font = NSFont.inter(24, .bold)

            iconContainerView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(22)
                make.centerY.equalToSuperview()
                make.width.height.equalTo(52)
            }
            categoryBadgeLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(20)
                make.trailing.equalToSuperview().offset(-22)
                make.height.equalTo(22)
                make.width.greaterThanOrEqualTo(74)
            }
            specialBadgeLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(20)
                make.trailing.equalTo(categoryBadgeLabel.snp.leading).offset(-8)
                make.height.equalTo(22)
                make.width.greaterThanOrEqualTo(62)
            }
            nameLabel.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(22)
                make.leading.equalTo(iconContainerView.snp.trailing).offset(18)
                make.trailing.lessThanOrEqualTo(specialBadgeLabel.snp.leading).offset(-16)
            }
            learnedCountLabel.snp.makeConstraints { make in
                make.top.equalTo(nameLabel.snp.bottom).offset(10)
                make.leading.equalTo(iconContainerView.snp.trailing).offset(18)
            }
            totalCountLabel.snp.makeConstraints { make in
                make.leading.equalTo(learnedCountLabel.snp.trailing).offset(4)
                make.bottom.equalTo(learnedCountLabel.snp.bottom).offset(-2)
                make.trailing.lessThanOrEqualToSuperview().offset(-22)
            }
            progressTitleLabel.snp.makeConstraints { make in
                make.leading.equalTo(iconContainerView.snp.trailing).offset(18)
                make.bottom.equalTo(progressBar.snp.top).offset(-8)
            }
            progressPercentLabel.snp.makeConstraints { make in
                make.trailing.equalToSuperview().offset(-22)
                make.centerY.equalTo(progressTitleLabel)
            }
            progressBar.snp.makeConstraints { make in
                make.leading.equalTo(iconContainerView.snp.trailing).offset(18)
                make.trailing.equalToSuperview().offset(-22)
                make.bottom.equalToSuperview().offset(-22)
                make.height.equalTo(6)
            }
        }

        needsLayout = true
        layoutSubtreeIfNeeded()
        updateUI()
    }

    private func updateUI() {
        guard let data else { return }
        let totalCount = max(data.entryCount, data.totalWords ?? data.entryCount)
        let progress = totalCount > 0 ? CGFloat(learnedCount) / CGFloat(totalCount) : 0
        let isVocabularyNotebook = data.isVocabularyNotebook
        nameLabel.stringValue = data.name
        categoryBadgeLabel.stringValue = data.category
        specialBadgeLabel.stringValue = badgeTitle ?? ""
        specialBadgeLabel.isHidden = (badgeTitle?.isEmpty ?? true)
        iconView.image = NSImage(systemSymbolName: isVocabularyNotebook ? "text.book.closed.fill" : "translate", accessibilityDescription: nil)
        iconView.contentTintColor = isVocabularyNotebook ? .systemOrange : LLAppearanceManager.shared.colors.accentColor
        iconContainerView.layer?.backgroundColor = (isVocabularyNotebook
            ? NSColor.systemOrange.withAlphaComponent(0.14)
            : LLAppearanceManager.shared.colors.accentColor.withAlphaComponent(0.1)).cgColor
        learnedCountLabel.textColor = isVocabularyNotebook ? .systemOrange : LLAppearanceManager.shared.colors.accentColor
        progressFill.layer?.backgroundColor = (isVocabularyNotebook ? NSColor.systemOrange : LLAppearanceManager.shared.colors.accentColor).cgColor
        learnedCountLabel.stringValue = "\(learnedCount)"
        totalCountLabel.stringValue = "/ \(totalCount) \(NSLocalizedString("words", comment: "Words unit"))"
        progressPercentLabel.stringValue = String(format: "%.1f%%", progress * 100)
        layoutSubtreeIfNeeded()
        let maxWidth = progressBar.bounds.width
        progressFillWidthConstraint?.update(offset: max(0, min(maxWidth, maxWidth * progress)))
    }

    private func updateCardAppearance(animated: Bool) {
        let changes = {
            if self.isSelected || self.isCurrentLearning || (self.data?.isVocabularyNotebook == true) {
                let highlightColor = self.data?.isVocabularyNotebook == true ? NSColor.systemOrange : LLAppearanceManager.shared.colors.accentColor
                self.layer?.borderColor = highlightColor.withAlphaComponent(0.28).cgColor
                self.layer?.shadowColor = NSColor.black.withAlphaComponent(0.08).cgColor
                self.layer?.shadowRadius = 16
                self.layer?.shadowOffset = CGSize(width: 0, height: -4)
            } else {
                self.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.4).cgColor
                self.layer?.shadowColor = NSColor.black.withAlphaComponent(0.06).cgColor
                self.layer?.shadowRadius = 10
                self.layer?.shadowOffset = CGSize(width: 0, height: -2)
            }
        }
        if animated {
            NSAnimationContext.runAnimationGroup { context in context.duration = 0.18; changes() }
        } else { changes() }
    }

    override func mouseDown(with event: NSEvent) { if let data { onClicked?(data) } }

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

    override func mouseExited(with event: NSEvent) { if !isSelected { updateCardAppearance(animated: true) } }
}
