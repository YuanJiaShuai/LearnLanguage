//
//  LLCurrentListCardView.swift
//  LearnLanguage
//
//  当前学习词库卡片 - 全部 frame 布局

import AppKit

final class LLCurrentListCardView: NSView {
    
    // MARK: - UI
    
    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Current Learning List", comment: ""))
        label.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
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
        label.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false; label.isBezeled = false; label.drawsBackground = false
        return label
    }()
    
    private let categoryLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false; label.isBezeled = false; label.drawsBackground = false
        return label
    }()
    
    private let progressBarBg: NSView = {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor(white: 0.9, alpha: 1).cgColor
        v.layer?.cornerRadius = 4
        return v
    }()
    
    private let progressBarFill: NSView = {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        v.layer?.cornerRadius = 4
        return v
    }()
    
    private let progressLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false; label.isBezeled = false; label.drawsBackground = false
        return label
    }()
    
    // 3个小统计
    private let stat1Icon = NSTextField(labelWithString: "📅")
    private let stat1Title: NSTextField = { let l = NSTextField(labelWithString: NSLocalizedString("Today's Learning", comment: "")); l.font = .systemFont(ofSize: 11); l.textColor = LLAppearanceManager.shared.colors.secondaryText; l.alignment = .center; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    private let stat1Value: NSTextField = { let l = NSTextField(labelWithString: "-"); l.font = .systemFont(ofSize: 14, weight: .semibold); l.textColor = LLAppearanceManager.shared.colors.primaryText; l.alignment = .center; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    
    private let stat2Icon = NSTextField(labelWithString: "📖")
    private let stat2Title: NSTextField = { let l = NSTextField(labelWithString: NSLocalizedString("Total Words", comment: "")); l.font = .systemFont(ofSize: 11); l.textColor = LLAppearanceManager.shared.colors.secondaryText; l.alignment = .center; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    private let stat2Value: NSTextField = { let l = NSTextField(labelWithString: "-"); l.font = .systemFont(ofSize: 14, weight: .semibold); l.textColor = LLAppearanceManager.shared.colors.primaryText; l.alignment = .center; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    
    private let stat3Icon = NSTextField(labelWithString: "✅")
    private let stat3Title: NSTextField = { let l = NSTextField(labelWithString: NSLocalizedString("Mastered", comment: "")); l.font = .systemFont(ofSize: 11); l.textColor = LLAppearanceManager.shared.colors.secondaryText; l.alignment = .center; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    private let stat3Value: NSTextField = { let l = NSTextField(labelWithString: "-"); l.font = .systemFont(ofSize: 14, weight: .semibold); l.textColor = LLAppearanceManager.shared.colors.primaryText; l.alignment = .center; l.isEditable = false; l.isBezeled = false; l.drawsBackground = false; return l }()
    
    private lazy var changeButton: NSButton = {
        let button = NSButton(title: NSLocalizedString("Change List", comment: ""), target: self, action: #selector(didClickChangeButton))
        button.bezelStyle = .rounded
        button.wantsLayer = true
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        button.layer?.cornerRadius = 6
        button.contentTintColor = .white
        return button
    }()
    
    var onChangeButtonClicked: (() -> Void)?
    private var progressRatio: CGFloat = 0
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
        layer?.cornerRadius = 12
        layer?.borderWidth = 1
        layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        
        for v in [stat1Icon, stat1Title, stat1Value,
                  stat2Icon, stat2Title, stat2Value,
                  stat3Icon, stat3Title, stat3Value] as [NSTextField] {
            v.isEditable = false; v.isBezeled = false; v.drawsBackground = false
            v.font = v.font // keep
        }
        [stat1Icon, stat2Icon, stat3Icon].forEach { $0.font = .systemFont(ofSize: 20); $0.alignment = .center }
        
        addSubview(titleLabel)
        addSubview(emptyStateLabel)
        addSubview(listNameLabel)
        addSubview(categoryLabel)
        addSubview(progressBarBg)
        progressBarBg.addSubview(progressBarFill)
        addSubview(progressLabel)
        addSubview(stat1Icon); addSubview(stat1Title); addSubview(stat1Value)
        addSubview(stat2Icon); addSubview(stat2Title); addSubview(stat2Value)
        addSubview(stat3Icon); addSubview(stat3Title); addSubview(stat3Value)
        addSubview(changeButton)
    }
    
    // MARK: - Layout
    
    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }
        
        // 标题
        titleLabel.frame = NSRect(x: 20, y: 20, width: w - 40, height: 22)
        
        // 切换按钮
        let btnW: CGFloat = 110
        let btnH: CGFloat = 30
        changeButton.frame = NSRect(x: w - 20 - btnW, y: h - 20 - btnH, width: btnW, height: btnH)
        
        if !hasContent {
            emptyStateLabel.isHidden = false
            listNameLabel.isHidden = true
            categoryLabel.isHidden = true
            progressBarBg.isHidden = true
            progressLabel.isHidden = true
            [stat1Icon, stat1Title, stat1Value, stat2Icon, stat2Title, stat2Value,
             stat3Icon, stat3Title, stat3Value].forEach { $0.isHidden = true }
            emptyStateLabel.frame = NSRect(x: 40, y: (h - 40) / 2, width: w - 80, height: 40)
            return
        }
        
        emptyStateLabel.isHidden = true
        listNameLabel.isHidden = false
        categoryLabel.isHidden = false
        progressBarBg.isHidden = false
        progressLabel.isHidden = false
        [stat1Icon, stat1Title, stat1Value, stat2Icon, stat2Title, stat2Value,
         stat3Icon, stat3Title, stat3Value].forEach { $0.isHidden = false }
        
        var y: CGFloat = 20 + 22 + 16
        listNameLabel.frame = NSRect(x: 20, y: y, width: w - 40, height: 24)
        y += 24 + 6
        categoryLabel.frame = NSRect(x: 20, y: y, width: w - 40, height: 18)
        y += 18 + 12
        
        // 进度条
        let barW = w - 40
        progressBarBg.frame = NSRect(x: 20, y: y, width: barW, height: 8)
        progressBarFill.frame = NSRect(x: 0, y: 0, width: barW * progressRatio, height: 8)
        y += 8 + 6
        progressLabel.frame = NSRect(x: 20, y: y, width: barW, height: 16)
        y += 16 + 16
        
        // 3列统计
        let statW = (w - 40) / 3
        let statH: CGFloat = 60
        for (i, views) in [(stat1Icon, stat1Title, stat1Value),
                           (stat2Icon, stat2Title, stat2Value),
                           (stat3Icon, stat3Title, stat3Value)].enumerated() {
            let x = 20 + CGFloat(i) * statW
            views.0.frame = NSRect(x: x, y: y, width: statW, height: 22)
            views.1.frame = NSRect(x: x, y: y + 22 + 2, width: statW, height: 16)
            views.2.frame = NSRect(x: x, y: y + 22 + 2 + 16 + 2, width: statW, height: 18)
        }
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
            needsLayout = true
            return
        }
        hasContent = true
        changeButton.title = NSLocalizedString("Change List", comment: "")
        listNameLabel.stringValue = list.name
        categoryLabel.stringValue = "📚 \(list.category)"
        
        let progress = LLSettingsStore.shared.getCurrentListProgress()
        progressRatio = CGFloat(progress.percentage / 100.0)
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
        needsLayout = true
    }
    
    @objc private func didClickChangeButton() {
        onChangeButtonClicked?()
    }
}
