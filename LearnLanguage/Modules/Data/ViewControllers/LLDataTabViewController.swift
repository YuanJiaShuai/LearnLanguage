//
//  LLDataTabViewController.swift
//  LearnLanguage
//
//  数据管理页面 - 包含备份、恢复、数据库维护等功能

import AppKit
import SnapKit
import UniformTypeIdentifiers

private struct LLLearningLabItem {
    let title: String
    let subtitle: String
    let description: String
    let symbolName: String
    let tintColor: NSColor
    let badge: String
    let footer: String
    let route: LLLearningLabRoute
}

private final class LLLearningLabBadgeTextFieldCell: NSTextFieldCell {
    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        var newRect = super.drawingRect(forBounds: rect)
        let textSize = cellSize(forBounds: rect)
        newRect.origin.y = rect.origin.y + (rect.height - textSize.height) / 2
        newRect.size.height = textSize.height
        return newRect
    }
}

private final class LLLearningLabCollectionItem: NSCollectionViewItem {
    private let cardView = NSView()
    private let iconWrap = NSView()
    private let iconView = NSImageView()
    private let badgeLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private let descriptionLabel = NSTextField(labelWithString: "")
    private let footerLabel = NSTextField(labelWithString: "")
    
    override func loadView() {
        view = NSView()
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        setupUI()
    }
    
    private func setupUI() {
        cardView.wantsLayer = true
        cardView.layer?.cornerRadius = 16
        cardView.layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
        cardView.layer?.borderWidth = 1
        cardView.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.4).cgColor
        cardView.layer?.shadowColor = NSColor.black.withAlphaComponent(0.06).cgColor
        cardView.layer?.shadowOpacity = 1
        cardView.layer?.shadowOffset = CGSize(width: 0, height: -2)
        cardView.layer?.shadowRadius = 10
        
        iconWrap.wantsLayer = true
        iconWrap.layer?.cornerRadius = 12
        cardView.addSubview(iconWrap)
        
        iconView.imageScaling = .scaleProportionallyDown
        iconWrap.addSubview(iconView)
        
        badgeLabel.font = NSFont.systemFont(ofSize: 10, weight: .semibold)
        badgeLabel.alignment = .center
        badgeLabel.cell = LLLearningLabBadgeTextFieldCell(textCell: "")
        badgeLabel.cell?.alignment = .center
        badgeLabel.cell?.usesSingleLineMode = true
        badgeLabel.cell?.wraps = false
        badgeLabel.cell?.isScrollable = false
        badgeLabel.wantsLayer = true
        badgeLabel.layer?.cornerRadius = 6
        badgeLabel.layer?.masksToBounds = true
        cardView.addSubview(badgeLabel)
        
        titleLabel.font = NSFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        cardView.addSubview(titleLabel)
        
        subtitleLabel.font = NSFont.systemFont(ofSize: 12, weight: .semibold)
        subtitleLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.65)
        cardView.addSubview(subtitleLabel)
        
        descriptionLabel.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        descriptionLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        descriptionLabel.lineBreakMode = .byWordWrapping
        descriptionLabel.maximumNumberOfLines = 0
        cardView.addSubview(descriptionLabel)
        
        footerLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        cardView.addSubview(footerLabel)
        
        iconWrap.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(24)
            make.width.height.equalTo(48)
        }
        
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        badgeLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.height.equalTo(22)
            make.width.greaterThanOrEqualTo(60)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconWrap.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(24)
        }
        
        footerLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().offset(-24)
            make.bottom.equalToSuperview().offset(-24)
        }
    }
    
    func configure(with item: LLLearningLabItem) {
        iconWrap.layer?.backgroundColor = item.tintColor.withAlphaComponent(0.12).cgColor
        iconView.image = NSImage(systemSymbolName: item.symbolName, accessibilityDescription: nil)
        iconView.contentTintColor = item.tintColor
        badgeLabel.stringValue = item.badge
        badgeLabel.textColor = item.tintColor
        badgeLabel.layer?.backgroundColor = item.tintColor.withAlphaComponent(0.12).cgColor
        titleLabel.stringValue = item.title
        subtitleLabel.stringValue = item.subtitle
        descriptionLabel.stringValue = item.description
        footerLabel.stringValue = item.footer
        footerLabel.textColor = item.tintColor.withAlphaComponent(0.88)
    }
}

final class LLDataTabViewController: NSViewController {
    
    var onOpenLearningLabRoute: ((LLLearningLabRoute) -> Void)?
    
    private enum Tab {
        case dataManagement
        case learningLab
    }
    
    // MARK: - UI Components
    
    // 页面标题
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Data Module Title", comment: ""))
        label.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.moduleTitleText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    // 标签按钮容器
    private lazy var tabContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        return view
    }()
    
    private lazy var dataManagementTabButton: NSButton = makeTabButton(title: NSLocalizedString("Data Module Title", comment: ""), action: #selector(switchToDataManagementTab))
    private lazy var learningLabTabButton: NSButton = makeTabButton(title: "学习实验室", action: #selector(switchToLearningLabTab))
    
    // 滚动容器
    private lazy var scrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.documentView = contentView
        return scroll
    }()
    
    // 内容容器
    private lazy var contentView: NSView = {
        let view = NSView()
        return view
    }()
    
    private lazy var learningLabContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.isHidden = true
        return view
    }()
    
    private lazy var learningLabScrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.documentView = learningLabCollectionView
        return scrollView
    }()
    
    private lazy var learningLabCollectionView: NSCollectionView = {
        let collectionView = NSCollectionView()
        collectionView.backgroundColors = [.clear]
        return collectionView
    }()
    
    private let learningLabItemIdentifier = NSUserInterfaceItemIdentifier("LLLearningLabCollectionItem")
    private let learningLabItemSpacing: CGFloat = 16
    private let learningLabItemsPerRow = 3
    private let learningLabItemHeight: CGFloat = 244
    private let learningLabSectionInsets = NSEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
    
    private let learningLabItems: [LLLearningLabItem] = [
        LLLearningLabItem(
            title: "语法笔记",
            subtitle: "Grammar Notes",
            description: "以阅读卡片和文档页面查看语法笔记，适合在学习间隙快速复习。",
            symbolName: "text.book.closed.fill",
            tintColor: NSColor.systemBlue,
            badge: "可用",
            footer: "打开语法笔记",
            route: .grammarNotes
        ),
        LLLearningLabItem(
            title: "词汇量评估",
            subtitle: "Vocabulary Assessment",
            description: "基于标准词库做 20 题快速测评，帮助你先估算当前词汇水平。",
            symbolName: "chart.bar.doc.horizontal.fill",
            tintColor: NSColor.systemTeal,
            badge: "可用",
            footer: "开始评估",
            route: .vocabularyAssessment
        )
    ]
    
    private var currentTab: Tab = .dataManagement

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 450))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        // 1. 添加标题
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.top.equalToSuperview().offset(28)
        }
        
        // 2. 添加标签按钮容器
        view.addSubview(tabContainer)
        tabContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(28)
            make.height.equalTo(28)
        }
        
        tabContainer.addSubview(dataManagementTabButton)
        dataManagementTabButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.greaterThanOrEqualTo(96)
        }
        
        tabContainer.addSubview(learningLabTabButton)
        learningLabTabButton.snp.makeConstraints { make in
            make.leading.equalTo(dataManagementTabButton.snp.trailing).offset(4)
            make.top.bottom.trailing.equalToSuperview()
            make.width.greaterThanOrEqualTo(96)
        }
        
        // 3. 添加滚动容器
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.right.equalToSuperview().offset(-28)
            make.top.equalTo(tabContainer.snp.bottom).offset(20)
            make.bottom.equalToSuperview().offset(-28)
        }
        
        // 4. 设置 contentView 的宽度约束
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        
        // 5. 创建功能卡片
        var lastCard: NSView?
        
        // 本地备份卡片
        let backupCard = createBackupCard()
        contentView.addSubview(backupCard)
        backupCard.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        lastCard = backupCard
        
        // 数据恢复卡片
        let restoreCard = createRestoreCard()
        contentView.addSubview(restoreCard)
        restoreCard.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(lastCard!.snp.bottom).offset(20)
        }
        lastCard = restoreCard
        
        // 数据库维护卡片
        let maintenanceCard = createMaintenanceCard()
        contentView.addSubview(maintenanceCard)
        maintenanceCard.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(lastCard!.snp.bottom).offset(20)
            make.bottom.equalToSuperview()
        }
        
        // 6. 学习实验室页面
        view.addSubview(learningLabContainer)
        learningLabContainer.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(28)
            make.bottom.equalToSuperview().offset(-28)
        }
        
        learningLabContainer.addSubview(learningLabScrollView)
        learningLabScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        setupLearningLabCollectionView()
        
        updateTabButtonStyles()
    }
    
    private func setupLearningLabCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = learningLabItemSpacing
        flowLayout.minimumLineSpacing = learningLabItemSpacing
        flowLayout.sectionInset = learningLabSectionInsets
        flowLayout.itemSize = learningLabItemSize(for: learningLabScrollView.contentView.bounds.width)
        
        learningLabCollectionView.collectionViewLayout = flowLayout
        learningLabCollectionView.delegate = self
        learningLabCollectionView.dataSource = self
        learningLabCollectionView.isSelectable = true
        learningLabCollectionView.allowsMultipleSelection = false
        learningLabCollectionView.backgroundColors = [.clear]
        learningLabCollectionView.register(
            LLLearningLabCollectionItem.self,
            forItemWithIdentifier: learningLabItemIdentifier
        )
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        updateLearningLabLayoutIfNeeded()
    }
    
    private func updateLearningLabLayoutIfNeeded() {
        guard let flowLayout = learningLabCollectionView.collectionViewLayout as? NSCollectionViewFlowLayout else { return }
        let contentWidth = learningLabScrollView.contentView.bounds.width
        let itemSize = learningLabItemSize(for: contentWidth)
        guard itemSize.width > 0 else { return }
        
        flowLayout.minimumInteritemSpacing = learningLabItemSpacing
        flowLayout.minimumLineSpacing = learningLabItemSpacing
        flowLayout.sectionInset = learningLabSectionInsets
        flowLayout.itemSize = itemSize
        flowLayout.invalidateLayout()
        
        let rowCount = ceil(CGFloat(learningLabItems.count) / CGFloat(learningLabItemsPerRow))
        let totalHeight = learningLabSectionInsets.top
            + learningLabSectionInsets.bottom
            + rowCount * learningLabItemHeight
            + max(0, rowCount - 1) * learningLabItemSpacing
        
        learningLabCollectionView.frame = NSRect(
            x: 0,
            y: 0,
            width: contentWidth,
            height: totalHeight
        )
    }
    
    private func learningLabItemSize(for containerWidth: CGFloat) -> NSSize {
        let usableWidth = max(containerWidth, 0)
        let totalSpacing = learningLabSectionInsets.left + learningLabSectionInsets.right + (learningLabItemSpacing * CGFloat(learningLabItemsPerRow - 1))
        let rawItemWidth = (usableWidth - totalSpacing) / CGFloat(learningLabItemsPerRow)
        let itemWidth = max(floor(rawItemWidth), 180)
        return NSSize(width: itemWidth, height: learningLabItemHeight)
    }
    
    @objc private func switchToDataManagementTab() {
        currentTab = .dataManagement
        updateTabButtonStyles()
        scrollView.isHidden = false
        learningLabContainer.isHidden = true
    }
    
    @objc private func switchToLearningLabTab() {
        currentTab = .learningLab
        updateTabButtonStyles()
        scrollView.isHidden = true
        learningLabContainer.isHidden = false
    }
    
    private func updateTabButtonStyles() {
        styleTabButton(dataManagementTabButton, selected: currentTab == .dataManagement)
        styleTabButton(learningLabTabButton, selected: currentTab == .learningLab)
    }
    
    private func makeTabButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        button.contentTintColor = LLAppearanceManager.shared.colors.secondaryText
        button.wantsLayer = true
        button.layer?.cornerRadius = 8
        return button
    }
    
    private func styleTabButton(_ button: NSButton, selected: Bool) {
        button.contentTintColor = selected
            ? LLAppearanceManager.shared.colors.accentColor
            : LLAppearanceManager.shared.colors.secondaryText
        button.layer?.backgroundColor = selected
            ? LLAppearanceManager.shared.colors.accentLightBackground.cgColor
            : NSColor.clear.cgColor
    }

    // MARK: - 创建功能卡片
    
    /// 创建本地备份卡片
    private func createBackupCard() -> NSView {
        let card = createCardContainer()
        
        // 图标
        let iconView = createIconView(systemName: "doc.badge.arrow.up.fill", color: NSColor.systemBlue)
        card.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(20)
            make.width.height.equalTo(24)
        }
        
        // 标题
        let titleLabel = createCardTitle(NSLocalizedString("Local Backup", comment: ""))
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView)
        }
        
        // 描述
        let descLabel = createCardDescription(NSLocalizedString("Backup Desc", comment: ""))
        card.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(iconView.snp.bottom).offset(12)
        }
        
        // 按钮容器
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12
        buttonStack.alignment = .centerY
        
        // 立即备份按钮
        let backupButton = createPrimaryButton(title: NSLocalizedString("Export Backup", comment: ""), icon: "arrow.down.doc.fill")
        backupButton.target = self
        backupButton.action = #selector(exportBackup)
        buttonStack.addArrangedSubview(backupButton)
        
        card.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(descLabel.snp.bottom).offset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        return card
    }
    
    /// 创建数据恢复卡片
    private func createRestoreCard() -> NSView {
        let card = createCardContainer()
        
        // 图标
        let iconView = createIconView(systemName: "arrow.counterclockwise.circle.fill", color: NSColor.systemOrange)
        card.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(20)
            make.width.height.equalTo(24)
        }
        
        // 标题
        let titleLabel = createCardTitle(NSLocalizedString("Data Restore", comment: ""))
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView)
        }
        
        // 描述
        let descLabel = createCardDescription(NSLocalizedString("Restore Desc", comment: ""))
        card.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(iconView.snp.bottom).offset(12)
        }
        
        // 恢复按钮
        let restoreButton = createSecondaryButton(title: NSLocalizedString("Select Restore File", comment: ""), icon: "arrow.up.doc.fill")
        restoreButton.target = self
        restoreButton.action = #selector(restoreBackup)
        card.addSubview(restoreButton)
        restoreButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(descLabel.snp.bottom).offset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        return card
    }
    
    /// 创建数据库维护卡片
    private func createMaintenanceCard() -> NSView {
        let card = createCardContainer()
        
        // 图标
        let iconView = createIconView(systemName: "wrench.and.screwdriver.fill", color: NSColor.systemPurple)
        card.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(20)
            make.width.height.equalTo(24)
        }
        
        // 标题
        let titleLabel = createCardTitle(NSLocalizedString("DB Maintenance", comment: ""))
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView)
        }
        
        // 描述
        let descLabel = createCardDescription(NSLocalizedString("DB Maintenance Desc", comment: ""))
        card.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(iconView.snp.bottom).offset(12)
        }
        
        // 按钮容器
        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12
        buttonStack.alignment = .centerY
        
        // 检查完整性按钮
        let checkButton = createSecondaryButton(title: NSLocalizedString("Check Integrity", comment: ""), icon: "checkmark.shield.fill")
        checkButton.target = self
        checkButton.action = #selector(checkDatabaseIntegrity)
        buttonStack.addArrangedSubview(checkButton)
        
        // 修复数据库按钮
        let repairButton = createSecondaryButton(title: NSLocalizedString("Repair DB", comment: ""), icon: "hammer.fill")
        repairButton.target = self
        repairButton.action = #selector(repairDatabase)
        buttonStack.addArrangedSubview(repairButton)
        
        // 导出统计按钮
        let statsButton = createSecondaryButton(title: NSLocalizedString("Reset Data", comment: ""), icon: "trash.fill")
        statsButton.target = self
        statsButton.action = #selector(resetAllData)
        buttonStack.addArrangedSubview(statsButton)
        
        card.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(descLabel.snp.bottom).offset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        return card
    }
    
    // MARK: - UI 辅助方法
    
    /// 创建卡片容器
    private func createCardContainer() -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
        view.layer?.cornerRadius = 12
        view.layer?.borderWidth = 1
        view.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        return view
    }
    
    /// 创建图标视图
    private func createIconView(systemName: String, color: NSColor) -> NSImageView {
        let imageView = NSImageView()
        if let image = NSImage(systemSymbolName: systemName, accessibilityDescription: nil) {
            image.isTemplate = true
            imageView.image = image
            imageView.contentTintColor = color
        }
        return imageView
    }
    
    /// 创建卡片标题
    private func createCardTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }
    
    /// 创建卡片描述
    private func createCardDescription(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        return label
    }
    
    /// 创建主要按钮（蓝色背景）
    private func createPrimaryButton(title: String, icon: String) -> NSButton {
        let button = NSButton(title: title, target: nil, action: nil)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        if let image = NSImage(systemSymbolName: icon, accessibilityDescription: nil) {
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeading
        }
        button.contentTintColor = .white
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.systemBlue.cgColor
        button.layer?.cornerRadius = 6
        return button
    }
    
    /// 创建次要按钮（灰色边框）
    private func createSecondaryButton(title: String, icon: String) -> NSButton {
        let button = NSButton(title: title, target: nil, action: nil)
        button.bezelStyle = .rounded
        button.controlSize = .regular
        if let image = NSImage(systemSymbolName: icon, accessibilityDescription: nil) {
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeading
        }
        return button
    }
    
    // MARK: - Actions

    @objc private func exportBackup() {
        let panel = NSSavePanel()
        if let type = UTType(filenameExtension: LLBackupManager.fileExtension) {
            panel.allowedContentTypes = [type]
        }
        panel.nameFieldStringValue = "LearnLanguage_\(dateString()).\(LLBackupManager.fileExtension)"
        panel.message = NSLocalizedString("Save Panel Backup Message", comment: "")
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            DispatchQueue.main.async {
                LLBackupManager.shared.exportBackup(to: url) { errorMsg in
                    let alert = NSAlert()
                    if let msg = errorMsg {
                        alert.messageText = NSLocalizedString("Backup Failed", comment: "")
                        alert.informativeText = msg
                        alert.alertStyle = .critical
                    } else {
                        alert.messageText = NSLocalizedString("Backup Success", comment: "")
                        alert.informativeText = "\(url.path)"
                        alert.alertStyle = .informational
                    }
                    alert.runModal()
                }
            }
        }
    }

    @objc private func restoreBackup() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if let type = UTType(filenameExtension: LLBackupManager.fileExtension) {
            panel.allowedContentTypes = [type]
        }
        panel.message = NSLocalizedString("Open Panel Restore Message", comment: "")
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            DispatchQueue.main.async {
                let confirm = NSAlert()
                confirm.messageText = NSLocalizedString("Confirm Restore", comment: "")
                confirm.informativeText = NSLocalizedString("Confirm Restore Desc", comment: "")
                confirm.alertStyle = .warning
                confirm.addButton(withTitle: NSLocalizedString("Restore", comment: ""))
                confirm.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
                guard confirm.runModal() == .alertFirstButtonReturn else { return }

                LLBackupManager.shared.restoreBackup(from: url) { errorMsg in
                    let alert = NSAlert()
                    if let msg = errorMsg {
                        alert.messageText = NSLocalizedString("Restore Failed", comment: "")
                        alert.informativeText = msg
                        alert.alertStyle = .critical
                    } else {
                        alert.messageText = NSLocalizedString("Restore Success", comment: "")
                        alert.informativeText = NSLocalizedString("Restore Success Desc", comment: "")
                        alert.alertStyle = .informational
                        alert.runModal()
                        NotificationCenter.default.post(name: .learnLanguageRefreshStatus, object: nil)
                        NotificationCenter.default.post(name: .learnLanguageReloadWordLists, object: nil)
                        return
                    }
                    alert.runModal()
                }
            }
        }
    }
    
    @objc private func checkDatabaseIntegrity() {
        let result = LLAppInitializer.shared.checkDatabaseIntegrity()
        
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Check Done", comment: "")
        alert.informativeText = result
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc private func repairDatabase() {
        LLAppInitializer.shared.repairDatabase()
    }
    
    @objc private func resetAllData() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Reset All Data", comment: "")
        alert.informativeText = NSLocalizedString("Reset All Data Desc", comment: "")
        alert.alertStyle = .critical
        alert.addButton(withTitle: NSLocalizedString("Reset Confirm Button", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        
        LLAppInitializer.shared.performReset()
        
        NotificationCenter.default.post(name: .learnLanguageRefreshStatus, object: nil)
        NotificationCenter.default.post(name: .learnLanguageReloadWordLists, object: nil)
        
        let doneAlert = NSAlert()
        doneAlert.messageText = NSLocalizedString("Reset Done", comment: "")
        doneAlert.informativeText = NSLocalizedString("Reset Done Desc", comment: "")
        doneAlert.alertStyle = .informational
        doneAlert.runModal()
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        return formatter.string(from: Date())
    }
}

// MARK: - Learning Lab Collection View

extension LLDataTabViewController: NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return learningLabItems.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        guard let item = collectionView.makeItem(
            withIdentifier: learningLabItemIdentifier,
            for: indexPath
        ) as? LLLearningLabCollectionItem else {
            assertionFailure("Expected LLLearningLabCollectionItem for learning lab collection view")
            return NSCollectionViewItem()
        }
        item.configure(with: learningLabItems[indexPath.item])
        return item
    }
}

extension LLDataTabViewController: NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first, learningLabItems.indices.contains(indexPath.item) else { return }
        let item = learningLabItems[indexPath.item]
        onOpenLearningLabRoute?(item.route)
        collectionView.deselectItems(at: indexPaths)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        return learningLabItemSize(for: learningLabContainer.bounds.width)
    }
}
