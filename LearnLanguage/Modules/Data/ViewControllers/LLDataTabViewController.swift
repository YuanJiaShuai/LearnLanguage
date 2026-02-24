//
//  LLDataTabViewController.swift
//  LearnLanguage
//
//  数据管理页面 - 包含备份、恢复、数据库维护等功能

import AppKit
import SnapKit
import UniformTypeIdentifiers

final class LLDataTabViewController: NSViewController {
    
    // MARK: - UI Components
    
    // 页面标题
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "数据管理")
        label.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.moduleTitleText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
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
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.mainBackground.cgColor
        
        // 1. 添加标题
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.top.equalToSuperview().offset(28)
        }
        
        // 2. 添加滚动容器
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.right.equalToSuperview().offset(-28)
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.bottom.equalToSuperview().offset(-28)
        }
        
        // 3. 设置 contentView 的宽度约束
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        
        // 4. 创建功能卡片
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
        }
        lastCard = maintenanceCard
        
        // 最近备份记录卡片
        let historyCard = createHistoryCard()
        contentView.addSubview(historyCard)
        historyCard.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(lastCard!.snp.bottom).offset(20)
            make.bottom.equalToSuperview()
        }
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
        let titleLabel = createCardTitle("本地备份")
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView)
        }
        
        // 描述
        let descLabel = createCardDescription("备份包含所有词库、学习记录、设置配置，文件为本地JSON格式")
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
        let backupButton = createPrimaryButton(title: "立即备份", icon: "arrow.down.doc.fill")
        backupButton.target = self
        backupButton.action = #selector(exportBackup)
        buttonStack.addArrangedSubview(backupButton)
        
        // 打开备份目录按钮
        let openDirButton = createSecondaryButton(title: "打开备份目录", icon: "folder.fill")
        openDirButton.target = self
        openDirButton.action = #selector(openBackupDirectory)
        buttonStack.addArrangedSubview(openDirButton)
        
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
        let titleLabel = createCardTitle("数据恢复")
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView)
        }
        
        // 描述
        let descLabel = createCardDescription("仅支持恢复本软件导出的备份文件，恢复将覆盖当前所有数据")
        card.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(iconView.snp.bottom).offset(12)
        }
        
        // 恢复按钮
        let restoreButton = createSecondaryButton(title: "选择备份文件恢复", icon: "arrow.up.doc.fill")
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
        let titleLabel = createCardTitle("数据库维护")
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView)
        }
        
        // 描述
        let descLabel = createCardDescription("检查和修复数据库问题，确保数据完整性")
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
        let checkButton = createSecondaryButton(title: "检查完整性", icon: "checkmark.shield.fill")
        checkButton.target = self
        checkButton.action = #selector(checkDatabaseIntegrity)
        buttonStack.addArrangedSubview(checkButton)
        
        // 修复数据库按钮
        let repairButton = createSecondaryButton(title: "修复数据库", icon: "hammer.fill")
        repairButton.target = self
        repairButton.action = #selector(repairDatabase)
        buttonStack.addArrangedSubview(repairButton)
        
        // 导出统计按钮
        let statsButton = createSecondaryButton(title: "导出统计", icon: "chart.bar.fill")
        statsButton.target = self
        statsButton.action = #selector(exportDatabaseStats)
        buttonStack.addArrangedSubview(statsButton)
        
        card.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(descLabel.snp.bottom).offset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        return card
    }
    
    /// 创建最近备份记录卡片
    private func createHistoryCard() -> NSView {
        let card = createCardContainer()
        
        // 图标
        let iconView = createIconView(systemName: "clock.arrow.circlepath", color: NSColor.systemGreen)
        card.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(20)
            make.width.height.equalTo(24)
        }
        
        // 标题
        let titleLabel = createCardTitle("最近备份记录")
        card.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalTo(iconView)
        }
        
        // 描述
        let descLabel = createCardDescription("暂无备份记录")
        card.addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(iconView.snp.bottom).offset(12)
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
        let records = LLLearningStore.shared.allRecords()
        guard let data = LLWordListStorage.shared.exportData(learningRecords: records) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "LearnLanguage_backup_\(dateString()).json"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? data.write(to: url)
            let alert = NSAlert()
            alert.messageText = "导出成功"
            alert.informativeText = "备份文件已保存到：\n\(url.path)"
            alert.alertStyle = .informational
            alert.runModal()
        }
    }
    
    @objc private func openBackupDirectory() {
        // 打开用户文档目录
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        NSWorkspace.shared.open(documentsURL)
    }

    @objc private func restoreBackup() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.json]
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let data = try? Data(contentsOf: url) else { return }
            let alert = NSAlert()
            alert.messageText = "确认恢复"
            alert.informativeText = "恢复将覆盖当前所有词库和学习记录，是否继续？"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "恢复")
            alert.addButton(withTitle: "取消")
            if alert.runModal() == .alertFirstButtonReturn, LLWordListStorage.shared.restoreFromData(data) {
                let done = NSAlert()
                done.messageText = "恢复成功"
                done.informativeText = "数据已成功恢复"
                done.alertStyle = .informational
                done.runModal()
                NotificationCenter.default.post(name: .learnLanguageRefreshStatus, object: nil)
                NotificationCenter.default.post(name: .learnLanguageReloadWordLists, object: nil)
            }
        }
    }
    
    @objc private func checkDatabaseIntegrity() {
        LLAppInitializer.shared.checkDatabaseIntegrity()
        
        let alert = NSAlert()
        alert.messageText = "检查完成"
        alert.informativeText = "数据库完整性检查已完成，详细信息请查看控制台输出"
        alert.alertStyle = .informational
        alert.runModal()
    }
    
    @objc private func repairDatabase() {
        LLAppInitializer.shared.repairDatabase()
    }
    
    @objc private func exportDatabaseStats() {
        let stats = LLAppInitializer.shared.exportDatabaseStats()
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "LearnLanguage_stats_\(dateString()).txt"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? stats.write(to: url, atomically: true, encoding: .utf8)
            let alert = NSAlert()
            alert.messageText = "导出成功"
            alert.informativeText = "统计信息已保存到：\n\(url.path)"
            alert.alertStyle = .informational
            alert.runModal()
        }
    }

    private func dateString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmm"
        return f.string(from: Date())
    }
}
