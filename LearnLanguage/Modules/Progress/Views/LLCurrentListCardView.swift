//
//  LLCurrentListCardView.swift
//  LearnLanguage
//
//  当前学习词库卡片

import AppKit
import SnapKit

final class LLCurrentListCardView: NSView {
    // MARK: - UI
    
    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Current Learning List", comment: ""))
        label.font = NSFont.inter(14, .semiBold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false; label.isBezeled = false; label.drawsBackground = false
        return label
    }()
    
    private let emptyStateLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("No Word List Selected", comment: ""))
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false; label.isBezeled = false; label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let listNameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.interDisplay(24, .bold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false; label.isBezeled = false; label.drawsBackground = false
        label.maximumNumberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let categoryLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.inter(13, .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false; label.isBezeled = false; label.drawsBackground = false
        label.maximumNumberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let progressBarBg: NSView = {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = LLAppearanceManager.shared.colors.surfaceContainer.cgColor
        v.layer?.cornerRadius = 3
        return v
    }()
    
    private let progressBarFill: NSView = {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        v.layer?.cornerRadius = 3
        return v
    }()
    
    private let progressLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.inter(13, .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false; label.isBezeled = false; label.drawsBackground = false
        label.maximumNumberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    // 3个小统计
    private let stat1Icon = NSImageView(image: NSImage(systemSymbolName: "calendar", accessibilityDescription: nil) ?? NSImage())
    private let stat1Title: NSTextField = { let l = NSTextField(labelWithString: NSLocalizedString("Today's Learning", comment: "")); l.font = .inter(11, .medium); l.textColor = LLAppearanceManager.shared.colors.tertiaryText; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    private let stat1Value: NSTextField = { let l = NSTextField(labelWithString: "-"); l.font = .inter(14, .semiBold); l.textColor = LLAppearanceManager.shared.colors.primaryText; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    
    private let stat2Icon = NSImageView(image: NSImage(systemSymbolName: "text.book.closed", accessibilityDescription: nil) ?? NSImage())
    private let stat2Title: NSTextField = { let l = NSTextField(labelWithString: NSLocalizedString("Current List Total Words", comment: "")); l.font = .inter(11, .medium); l.textColor = LLAppearanceManager.shared.colors.tertiaryText; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    private let stat2Value: NSTextField = { let l = NSTextField(labelWithString: "-"); l.font = .inter(14, .semiBold); l.textColor = LLAppearanceManager.shared.colors.primaryText; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    
    private let stat3Icon = NSImageView(image: NSImage(systemSymbolName: "checkmark.seal", accessibilityDescription: nil) ?? NSImage())
    private let stat3Title: NSTextField = { let l = NSTextField(labelWithString: NSLocalizedString("Mastered", comment: "")); l.font = .inter(11, .medium); l.textColor = LLAppearanceManager.shared.colors.tertiaryText; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    private let stat3Value: NSTextField = { let l = NSTextField(labelWithString: "-"); l.font = .inter(14, .semiBold); l.textColor = LLAppearanceManager.shared.colors.primaryText; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    
    private lazy var changeButton: NSButton = {
        let button = NSButton(title: NSLocalizedString("Change List", comment: ""), target: self, action: #selector(didClickChangeButton))
        button.bezelStyle = .rounded
        button.font = NSFont.inter(13, .semiBold)
        button.wantsLayer = true
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        button.layer?.cornerRadius = 6
        button.contentTintColor = .white
        return button
    }()
    
    var onChangeButtonClicked: (() -> Void)?
    private var statsStack: NSStackView?
    private var progressRatio: CGFloat = 0
    private var progressFillWidthConstraint: Constraint?
    private var hasContent = false
    
    // MARK: - Init
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
        loadData()
        observeNotifications()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = LLAppearanceManager.shared.colors.cardBackground.cgColor
        layer?.cornerRadius = 10
        layer?.borderWidth = 1
        layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.6).cgColor
        
        for v in [stat1Title, stat1Value, stat2Title, stat2Value, stat3Title, stat3Value] as [NSTextField] {
            v.isEditable = false; v.isBezeled = false; v.drawsBackground = false
            v.font = v.font // keep
        }
        [stat1Icon, stat2Icon, stat3Icon].forEach {
            $0.contentTintColor = LLAppearanceManager.shared.colors.accentColor
            $0.imageScaling = .scaleProportionallyDown
        }
        
        addSubview(titleLabel)
        addSubview(emptyStateLabel)
        addSubview(listNameLabel)
        addSubview(categoryLabel)
        addSubview(progressBarBg)
        progressBarBg.addSubview(progressBarFill)
        addSubview(progressLabel)
        addSubview(changeButton)

        let statsStack = NSStackView(views: [
            makeStatRow(icon: stat1Icon, title: stat1Title, value: stat1Value),
            makeStatRow(icon: stat2Icon, title: stat2Title, value: stat2Value),
            makeStatRow(icon: stat3Icon, title: stat3Title, value: stat3Value)
        ])
        self.statsStack = statsStack
        statsStack.orientation = .vertical
        statsStack.alignment = .leading
        statsStack.distribution = .fillEqually
        statsStack.spacing = 10
        addSubview(statsStack)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
        }

        changeButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(CGSize(width: 110, height: 30))
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }

        listNameLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.top.equalTo(titleLabel.snp.bottom).offset(14)
            make.trailing.lessThanOrEqualTo(changeButton.snp.leading).offset(-12)
            make.height.equalTo(30)
        }

        categoryLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(listNameLabel)
            make.top.equalTo(listNameLabel.snp.bottom).offset(6)
            make.height.equalTo(18)
        }

        progressLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(listNameLabel)
            make.top.equalTo(categoryLabel.snp.bottom).offset(22)
            make.height.equalTo(18)
        }

        progressBarBg.snp.makeConstraints { make in
            make.leading.trailing.equalTo(listNameLabel)
            make.top.equalTo(progressLabel.snp.bottom).offset(8)
            make.height.equalTo(6)
        }

        progressBarFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            progressFillWidthConstraint = make.width.equalTo(0).constraint
        }

        for view in [stat1Icon, stat1Title, stat1Value, stat2Icon, stat2Title, stat2Value, stat3Icon, stat3Title, stat3Value] as [NSView] {
            view.isHidden = true
        }

        statsStack.snp.makeConstraints { make in
            make.top.equalTo(changeButton.snp.bottom).offset(22)
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(22)
            make.width.equalTo(176)
        }

        [listNameLabel, categoryLabel, progressLabel, progressBarBg].forEach { view in
            view.snp.makeConstraints { make in
                make.trailing.lessThanOrEqualTo(statsStack.snp.leading).offset(-24)
            }
        }
    }

    private func makeStatRow(icon: NSImageView, title: NSTextField, value: NSTextField) -> NSStackView {
        let textStack = NSStackView(views: [title, value])
        textStack.orientation = .vertical
        textStack.alignment = .leading
        textStack.spacing = 2

        let row = NSStackView(views: [icon, textStack])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 8

        icon.snp.makeConstraints { make in
            make.size.equalTo(18)
        }

        return row
    }

    override func layout() {
        super.layout()
        progressFillWidthConstraint?.update(offset: progressBarBg.bounds.width * progressRatio)
    }
    
    // MARK: - Data
    
    private func observeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: .learnLanguageCurrentListChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: .learnLanguageRefreshStatus, object: nil)
    }
    
    @objc private func loadData() {
        guard let list = LLSettingsStore.shared.currentWordList else {
            hasContent = false
            changeButton.title = NSLocalizedString("Select List", comment: "")
            [listNameLabel, categoryLabel, progressBarBg, progressLabel,
             stat1Icon, stat1Title, stat1Value, stat2Icon, stat2Title, stat2Value,
             stat3Icon, stat3Title, stat3Value].forEach { $0.isHidden = true }
            statsStack?.isHidden = true
            emptyStateLabel.isHidden = false
            return
        }
        hasContent = true
        changeButton.title = NSLocalizedString("Change List", comment: "")
        listNameLabel.stringValue = list.name
        categoryLabel.stringValue = list.category
        
        let progress = LLSettingsStore.shared.getCurrentListProgress()
        progressRatio = min(1, max(0, CGFloat(progress.percentage / 100.0)))
        progressLabel.stringValue = String(format: NSLocalizedString("Learned %d/%d words (%.1f%%)", comment: ""), progress.learned, progress.total, progress.percentage)
        
        let todayCount = LLSettingsStore.shared.getCurrentListTodayCount()
        stat1Value.stringValue = "\(todayCount) " + NSLocalizedString("words", comment: "")
        stat2Value.stringValue = "\(list.entryCount) " + NSLocalizedString("words", comment: "")
        
        let mastered: Int
        do {
            let stats = try LLDatabaseManager.shared.getWordListProgressStats(wordListId: list.id)
            mastered = stats.mastered
        } catch {
            mastered = 0
        }
        stat3Value.stringValue = "\(mastered) " + NSLocalizedString("words", comment: "")
        emptyStateLabel.isHidden = true
        [listNameLabel, categoryLabel, progressBarBg, progressLabel,
         stat1Icon, stat1Title, stat1Value, stat2Icon, stat2Title, stat2Value,
         stat3Icon, stat3Title, stat3Value].forEach { $0.isHidden = false }
        statsStack?.isHidden = false
        progressFillWidthConstraint?.update(offset: progressBarBg.bounds.width * progressRatio)
        needsLayout = true
    }
    
    @objc private func didClickChangeButton() {
        onChangeButtonClicked?()
    }
}
