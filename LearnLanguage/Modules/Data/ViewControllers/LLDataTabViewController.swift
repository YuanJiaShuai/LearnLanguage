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
        let label = NSTextField(labelWithString: NSLocalizedString("Data Module Title", comment: ""))
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
        panel.begin { [weak self] response in
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
        panel.begin { [weak self] response in
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
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmm"
        return f.string(from: Date())
    }
}
