//
//  LLCurrentListCardView.swift
//  LearnLanguage
//
//  当前学习词库卡片

import AppKit
import SnapKit

final class LLCurrentListCardView: NSView {
    
    // MARK: - UI Components
    
    private lazy var containerView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.cardBackground.cgColor
        view.layer?.cornerRadius = 12
        view.layer?.borderWidth = 1
        view.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        return view
    }()
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "当前学习词库")
        label.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var emptyStateLabel: NSTextField = {
        let label = NSTextField(labelWithString: "还未选择学习词库\n请前往「词库管理」选择一个词库开始学习")
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        label.maximumNumberOfLines = 2
        return label
    }()
    
    private lazy var contentStackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        return stack
    }()
    
    private lazy var listNameLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var categoryLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var progressContainerView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        return view
    }()
    
    private lazy var progressBarBackground: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(white: 0.9, alpha: 1).cgColor
        view.layer?.cornerRadius = 4
        return view
    }()
    
    private lazy var progressBarFill: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        view.layer?.cornerRadius = 4
        return view
    }()
    
    private lazy var progressLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var statsStackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 24
        stack.distribution = .fillEqually
        return stack
    }()
    
    private lazy var changeButton: NSButton = {
        let button = NSButton(title: "切换词库", target: self, action: #selector(didClickChangeButton))
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.wantsLayer = true
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        button.layer?.cornerRadius = 6
        button.contentTintColor = .white
        return button
    }()
    
    // MARK: - Properties
    
    var onChangeButtonClicked: (() -> Void)?
    private var progressWidthConstraint: Constraint?
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadData()
        observeNotifications()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        containerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        containerView.addSubview(emptyStateLabel)
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        containerView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        // 添加词库名称
        contentStackView.addArrangedSubview(listNameLabel)
        
        // 添加分类标签
        contentStackView.addArrangedSubview(categoryLabel)
        
        // 添加进度条容器
        contentStackView.addArrangedSubview(progressContainerView)
        progressContainerView.snp.makeConstraints { make in
            make.width.equalTo(contentStackView)
            make.height.equalTo(40)
        }
        
        progressContainerView.addSubview(progressBarBackground)
        progressBarBackground.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(8)
        }
        
        progressBarBackground.addSubview(progressBarFill)
        progressBarFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            progressWidthConstraint = make.width.equalTo(0).constraint
        }
        
        progressContainerView.addSubview(progressLabel)
        progressLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBarBackground.snp.bottom).offset(8)
            make.leading.equalToSuperview()
        }
        
        // 添加统计信息
        contentStackView.addArrangedSubview(statsStackView)
        statsStackView.snp.makeConstraints { make in
            make.width.equalTo(contentStackView)
        }
        
        // 添加切换按钮
        containerView.addSubview(changeButton)
        changeButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(100)
        }
        
        contentStackView.snp.makeConstraints { make in
            make.bottom.lessThanOrEqualTo(changeButton.snp.top).offset(-16)
        }
    }
    
    private func observeNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadData),
            name: .learnLanguageCurrentListChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadData),
            name: .learnLanguageRefreshStatus,
            object: nil
        )
    }
    
    // MARK: - Data Loading
    
    @objc private func loadData() {
        guard let list = LLSettingsStore.shared.currentWordList else {
            showEmptyState()
            return
        }
        
        showContent()
        
        // 更新词库信息
        listNameLabel.stringValue = list.name
        categoryLabel.stringValue = "📚 \(list.category)"
        
        // 更新进度
        let progress = LLSettingsStore.shared.getCurrentListProgress()
        updateProgress(learned: progress.learned, total: progress.total, percentage: progress.percentage)
        
        // 更新统计信息
        updateStats(list: list)
    }
    
    private func showEmptyState() {
        emptyStateLabel.isHidden = false
        contentStackView.isHidden = true
        changeButton.title = "选择词库"
    }
    
    private func showContent() {
        emptyStateLabel.isHidden = true
        contentStackView.isHidden = false
        changeButton.title = "切换词库"
    }
    
    private func updateProgress(learned: Int, total: Int, percentage: Double) {
        let progressWidth = containerView.bounds.width - 40
        let fillWidth = progressWidth * (percentage / 100.0)
        
        progressWidthConstraint?.update(offset: fillWidth)
        progressLabel.stringValue = "已学习 \(learned) / \(total) 词 (\(String(format: "%.1f", percentage))%)"
        
        // 添加动画
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.allowsImplicitAnimation = true
            progressBarFill.layoutSubtreeIfNeeded()
        }
    }
    
    private func updateStats(list: WordList) {
        // 清空旧的统计视图
        statsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 今日学习
        let todayCount = LLSettingsStore.shared.getCurrentListTodayCount()
        let todayStatView = createStatView(icon: "📅", title: "今日学习", value: "\(todayCount) 词")
        statsStackView.addArrangedSubview(todayStatView)
        
        // 总词数
        let totalStatView = createStatView(icon: "📖", title: "总词数", value: "\(list.entryCount) 词")
        statsStackView.addArrangedSubview(totalStatView)
        
        // 掌握情况
        let know: Int
        do {
            let stats = try LLDatabaseManager.shared.getWordListProgressStats(wordListId: list.id)
            know = stats.mastered
        } catch {
            LLLogger.error("❌ 获取掌握统计失败：\(error)")
            know = 0
        }
        let masteredStatView = createStatView(icon: "✅", title: "已掌握", value: "\(know) 词")
        statsStackView.addArrangedSubview(masteredStatView)
    }
    
    private func createStatView(icon: String, title: String, value: String) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        
        let iconLabel = NSTextField(labelWithString: icon)
        iconLabel.font = NSFont.systemFont(ofSize: 20)
        iconLabel.isEditable = false
        iconLabel.isBezeled = false
        iconLabel.drawsBackground = false
        iconLabel.alignment = .center
        
        let titleLabel = NSTextField(labelWithString: title)
        titleLabel.font = NSFont.systemFont(ofSize: 11)
        titleLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        titleLabel.isEditable = false
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.alignment = .center
        
        let valueLabel = NSTextField(labelWithString: value)
        valueLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        valueLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        valueLabel.isEditable = false
        valueLabel.isBezeled = false
        valueLabel.drawsBackground = false
        valueLabel.alignment = .center
        
        container.addSubview(iconLabel)
        container.addSubview(titleLabel)
        container.addSubview(valueLabel)
        
        iconLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconLabel.snp.bottom).offset(4)
            make.centerX.equalToSuperview()
        }
        
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func didClickChangeButton() {
        onChangeButtonClicked?()
    }
}

