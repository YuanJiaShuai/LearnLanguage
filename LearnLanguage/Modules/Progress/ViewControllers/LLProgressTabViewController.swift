//
//  LLProgressTabViewController.swift
//  LearnLanguage
//
//  学习记录模块 - 包含学习统计和错题记录两个子标签

import AppKit
import SnapKit
import UniformTypeIdentifiers

final class LLProgressTabViewController: NSViewController {

    // MARK: - UI Components
    
    // 页面标题
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "学习记录")
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
    
    // 子标签按钮
    private lazy var statTabButton: NSButton = {
        let button = NSButton(title: "学习统计", target: self, action: #selector(switchToStatTab))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        return button
    }()
    
    private lazy var wrongTabButton: NSButton = {
        let button = NSButton(title: "错题记录", target: self, action: #selector(switchToWrongTab))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        return button
    }()
    
    // 学习统计页面容器
    private lazy var statContentView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        return view
    }()
    
    // 错题记录页面容器
    private lazy var wrongContentView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.isHidden = true
        return view
    }()
    
    // 滚动容器（用于学习统计页面）
    private lazy var statScrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        return scroll
    }()
    
    // 滚动容器（用于错题记录页面）
    private lazy var wrongScrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        return scroll
    }()
    
    // 卡片视图组件
    private var currentListCard: LLCurrentListCardView!
    private var totalWordsCard: LLStatCardView!
    private var progressCard: LLProgressCardView!
    private var streakCard: LLStatCardView!
    private var trendCard: LLTrendCardView!
    private var todayRecordCard: LLTodayRecordCardView!
    private var wrongRecordCard: LLWrongRecordCardView!
    
    // 错题记录表格
    private var wrongTableView: NSTableView?
    private var wrongRecords: [LLDBWrongRecord] = []
    
    // 当前选中的标签
    private enum Tab {
        case stat
        case wrong
    }
    private var currentTab: Tab = .stat
    
    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 450))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        
        // 监听数据变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(loadData),
            name: .learnLanguageRefreshStatus,
            object: nil
        )
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        loadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.mainBackground.cgColor
        
        // 添加标题
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().offset(28)
        }
        
        // 添加标签按钮容器
        view.addSubview(tabContainer)
        tabContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(28)
            make.height.equalTo(28)
        }
        
        // 添加标签按钮
        tabContainer.addSubview(statTabButton)
        statTabButton.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.greaterThanOrEqualTo(80)
        }
        
        tabContainer.addSubview(wrongTabButton)
        wrongTabButton.snp.makeConstraints { make in
            make.leading.equalTo(statTabButton.snp.trailing).offset(4)
            make.top.bottom.trailing.equalToSuperview()
            make.width.greaterThanOrEqualTo(80)
        }
        
        // 添加学习统计页面
        view.addSubview(statContentView)
        statContentView.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(28)
            make.bottom.equalToSuperview().offset(-28)
        }
        setupStatContent()
        
        // 添加错题记录页面
        view.addSubview(wrongContentView)
        wrongContentView.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(28)
            make.bottom.equalToSuperview().offset(-28)
        }
        setupWrongContent()
        
        // 默认选中学习统计
        updateTabButtonStyles()
    }
    
    private func setupStatContent() {
        // 添加滚动视图
        statContentView.addSubview(statScrollView)
        statScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 创建内容容器
        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        statScrollView.documentView = contentView
        
        // 关键：设置 contentView 的宽度约束
        contentView.snp.makeConstraints { make in
            make.width.equalTo(statScrollView)
        }
        
        // 当前学习词库卡片
        currentListCard = LLCurrentListCardView()
        currentListCard.onChangeButtonClicked = { [weak self] in
            self?.showWordListSelector()
        }
        contentView.addSubview(currentListCard)
        currentListCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(280)
        }
        
        // 统计卡片网格容器
        let statsGrid = NSView()
        statsGrid.wantsLayer = true
        contentView.addSubview(statsGrid)
        statsGrid.snp.makeConstraints { make in
            make.top.equalTo(currentListCard.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(120)
        }
        
        // 使用新的 View 组件创建卡片
        totalWordsCard = LLStatCardView(icon: "📚", description: "累计学习单词")
        statsGrid.addSubview(totalWordsCard)
        totalWordsCard.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
        }
        
        progressCard = LLProgressCardView()
        statsGrid.addSubview(progressCard)
        progressCard.snp.makeConstraints { make in
            make.leading.equalTo(totalWordsCard.snp.trailing).offset(16)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(totalWordsCard)
        }
        
        streakCard = LLStatCardView(icon: "🔥", description: "连续学习天数")
        statsGrid.addSubview(streakCard)
        streakCard.snp.makeConstraints { make in
            make.leading.equalTo(progressCard.snp.trailing).offset(16)
            make.trailing.top.bottom.equalToSuperview()
            make.width.equalTo(totalWordsCard)
        }
        
        // 近7天学习趋势卡片
        trendCard = LLTrendCardView()
        contentView.addSubview(trendCard)
        trendCard.snp.makeConstraints { make in
            make.top.equalTo(statsGrid.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(200)
        }
        
        // 今日学习记录卡片
        todayRecordCard = LLTodayRecordCardView()
        todayRecordCard.onExportButtonClicked = { [weak self] in
            self?.exportRecords()
        }
        contentView.addSubview(todayRecordCard)
        todayRecordCard.snp.makeConstraints { make in
            make.top.equalTo(trendCard.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(300)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func setupWrongContent() {
        // 创建表格容器
        let tableContainer = NSView()
        tableContainer.wantsLayer = true
        tableContainer.layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
        tableContainer.layer?.cornerRadius = 8
        tableContainer.layer?.borderWidth = 1
        tableContainer.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        
        wrongContentView.addSubview(tableContainer)
        tableContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 创建 TableView
        let tableView = NSTableView()
        tableView.style = .fullWidth
        tableView.rowHeight = 60
        tableView.backgroundColor = .clear
        tableView.gridStyleMask = [.solidHorizontalGridLineMask]
        tableView.gridColor = LLAppearanceManager.shared.colors.borderColor
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.selectionHighlightStyle = .regular
        
        // 添加列
        let audioColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("audio"))
        audioColumn.title = "发音"
        audioColumn.width = 70
        audioColumn.minWidth = 60
        tableView.addTableColumn(audioColumn)
        
        let wordColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("word"))
        wordColumn.title = "单词"
        wordColumn.width = 130
        wordColumn.minWidth = 100
        tableView.addTableColumn(wordColumn)
        
        let meaningColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("meaning"))
        meaningColumn.title = "释义"
        meaningColumn.width = 180
        meaningColumn.minWidth = 150
        tableView.addTableColumn(meaningColumn)
        
        let errorCountColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("errorCount"))
        errorCountColumn.title = "错误次数"
        errorCountColumn.width = 90
        errorCountColumn.minWidth = 80
        tableView.addTableColumn(errorCountColumn)
        
        let actionColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("action"))
        actionColumn.title = "操作"
        actionColumn.width = 140
        actionColumn.minWidth = 120
        tableView.addTableColumn(actionColumn)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // 创建滚动视图
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = tableView
        
        tableContainer.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
        
        // 保存引用
        wrongTableView = tableView
    }
    
    // MARK: - Actions
    
    @objc private func switchToStatTab() {
        currentTab = .stat
        updateTabButtonStyles()
        statContentView.isHidden = false
        wrongContentView.isHidden = true
    }
    
    @objc private func switchToWrongTab() {
        currentTab = .wrong
        updateTabButtonStyles()
        statContentView.isHidden = true
        wrongContentView.isHidden = false
    }
    
    private func updateTabButtonStyles() {
        let activeColor = LLAppearanceManager.shared.colors.accentColor
        let inactiveColor = NSColor(srgbRed: 0.96, green: 0.96, blue: 0.97, alpha: 1)
        
        // 确保按钮有 layer
        statTabButton.wantsLayer = true
        wrongTabButton.wantsLayer = true
        
        if currentTab == .stat {
            statTabButton.layer?.backgroundColor = activeColor.cgColor
            statTabButton.contentTintColor = .white
            wrongTabButton.layer?.backgroundColor = inactiveColor.cgColor
            wrongTabButton.contentTintColor = LLAppearanceManager.shared.colors.primaryText
        } else {
            statTabButton.layer?.backgroundColor = inactiveColor.cgColor
            statTabButton.contentTintColor = LLAppearanceManager.shared.colors.primaryText
            wrongTabButton.layer?.backgroundColor = activeColor.cgColor
            wrongTabButton.contentTintColor = .white
        }
    }
    
    @objc private func batchReview() {
        let alert = NSAlert()
        alert.messageText = "批量复习"
        alert.informativeText = "此功能将开启错题复习模式，是否继续？"
        alert.addButton(withTitle: "开始复习")
        alert.addButton(withTitle: "取消")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // TODO: 实现批量复习逻辑
            LLLogger.info("开始批量复习错题")
        }
    }
    
    @objc private func exportRecords() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "学习记录_\(Date().timeIntervalSince1970).json"
        savePanel.message = "导出学习记录"
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                // TODO: 实现导出逻辑
                LLLogger.info("导出到: \(url.path)")
            }
        }
    }
    
    // MARK: - Data Loading
    
    @objc private func loadData() {
        guard isViewLoaded else { return }
        
        let listId = LLSettingsStore.shared.currentListId
        
        // 从 WCDB 获取统计数据
        do {
            let todayCount = try LLDatabaseManager.shared.getTodayLearnedCount(wordListId: listId)
            let stats: (total: Int, learned: Int, mastered: Int, learning: Int)
            if let listId = listId {
                stats = try LLDatabaseManager.shared.getWordListProgressStats(wordListId: listId)
            } else {
                stats = (0, 0, 0, 0)
            }
            let totalWords = stats.learned
            
            // 学习天数暂时保留 LLLearningStore 计算（WCDB 暂无此方法）
            let days = LLLearningStore.shared.totalLearningDays(listId: listId)
            
            // 使用新的 View 组件更新数据
            totalWordsCard?.updateNumber("\(totalWords)")
            streakCard?.updateNumber("\(days)")
            
            // 今日进度（假设目标是50个）
            let todayGoal = 50
            progressCard?.updateProgress(current: todayCount, total: todayGoal)
        } catch {
            LLLogger.error("❌ 加载统计数据失败：\(error)")
        }
        
        // 加载今日学习记录
        loadTodayRecords(listId: listId)
        
        // 加载错题记录
        loadWrongRecords(listId: listId)
    }
    
    private func loadTodayRecords(listId: String?) {
        // 使用新的 View 组件获取滚动视图
        guard let scrollView = todayRecordCard?.getScrollView() else { return }
        guard let listView = todayRecordCard?.getListView() else { return }
        
        listView.subviews.forEach { $0.removeFromSuperview() }
        
        // 从 WCDB 获取今日学习记录
        let todayRecords: [LLDBLearningProgress]
        do {
            let allProgress = try LLDatabaseManager.shared.getAllLearningProgress(wordListId: listId ?? "")
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            todayRecords = allProgress.filter { record in
                let date = Date(timeIntervalSince1970: record.lastSeenAt ?? 0)
                return cal.isDate(date, inSameDayAs: today)
            }.sorted { ($0.lastSeenAt ?? 0) > ($1.lastSeenAt ?? 0) }
        } catch {
            LLLogger.error("❌ 加载今日学习记录失败：\(error)")
            return
        }
        
        if todayRecords.isEmpty {
            let emptyLabel = NSTextField(labelWithString: "今天还没有学习记录")
            emptyLabel.font = NSFont.systemFont(ofSize: 14)
            emptyLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
            emptyLabel.isEditable = false
            emptyLabel.isBezeled = false
            emptyLabel.drawsBackground = false
            emptyLabel.alignment = .center
            listView.addSubview(emptyLabel)
            emptyLabel.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(scrollView)
            }
            listView.snp.makeConstraints { make in
                make.width.equalTo(scrollView)
                make.height.equalTo(100)
            }
            return
        }
        
        let container = NSView()
        container.wantsLayer = true
        listView.addSubview(container)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }
        
        var lastView: NSView?
        for (index, record) in todayRecords.prefix(20).enumerated() {
            let wordText = getWordText(wordId: record.wordId ?? "", listId: record.wordListId ?? "")
            let feedbackIcon = getFeedbackIconFromString(feedback: record.lastFeedback ?? "")
            let itemView = LLRecordItemView(
                wordText: wordText,
                feedbackIcon: feedbackIcon,
                time: Date(timeIntervalSince1970: record.lastSeenAt ?? 0),
                showBorder: index < todayRecords.count - 1
            )
            container.addSubview(itemView)
            itemView.snp.makeConstraints { make in
                if let last = lastView {
                    make.top.equalTo(last.snp.bottom)
                } else {
                    make.top.equalToSuperview().offset(8)
                }
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(50)
            }
            lastView = itemView
        }
        
        if let last = lastView {
            last.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-8)
            }
        }
    }
    
    private func loadWrongRecords(listId: String?) {
        // 从数据库读取错题记录
        do {
            if let listId = listId {
                wrongRecords = try LLDatabaseManager.shared.getWrongRecords(forListId: listId, onlyUnreviewed: true)
            } else {
                wrongRecords = try LLDatabaseManager.shared.getAllUnreviewedWrongRecords()
            }
            
            LLLogger.info("✅ 加载了 \(wrongRecords.count) 条错题记录")
            
            // 刷新表格
            wrongTableView?.reloadData()
            
        } catch {
            LLLogger.error("❌ 加载错题记录失败：\(error)")
            wrongRecords = []
            wrongTableView?.reloadData()
        }
    }
    
    @objc private func markAsKnown(wordId: String, listId: String) {
        do {
            try LLDatabaseManager.shared.markWrongRecordAsReviewed(wordId: wordId, listId: listId)
            LLLogger.info("✅ 已标记为已掌握: \(wordId)")
            loadData()
        } catch {
            LLLogger.error("❌ 标记失败：\(error)")
        }
    }
    
    @objc private func reviewWord(wordId: String) {
        // TODO: 实现立即复习的逻辑
        LLLogger.info("立即复习: \(wordId)")
    }
    
    private func showWordListSelector() {
        let alert = NSAlert()
        alert.messageText = "选择学习词库"
        alert.informativeText = "请选择一个词库作为当前学习词库"
        
        // 获取所有词库
        let allLists = LLWordListStorage.shared.allLists()
        
        if allLists.isEmpty {
            alert.informativeText = "暂无可用词库，请先导入词库"
            alert.addButton(withTitle: "确定")
            alert.runModal()
            return
        }
        
        // 创建词库选择器
        let popUpButton = NSPopUpButton()
        popUpButton.frame = NSRect(x: 0, y: 0, width: 300, height: 26)
        
        for list in allLists {
            let title = "\(list.name) (\(list.entryCount) 词)"
            popUpButton.addItem(withTitle: title)
            popUpButton.lastItem?.representedObject = list.id
        }
        
        // 选中当前词库
        if let currentId = LLSettingsStore.shared.currentListId,
           let index = allLists.firstIndex(where: { $0.id == currentId }) {
            popUpButton.selectItem(at: index)
        }
        
        alert.accessoryView = popUpButton
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let selectedId = popUpButton.selectedItem?.representedObject as? String {
                LLSettingsStore.shared.currentListId = selectedId
                LLLogger.info("✅ 已切换到词库: \(popUpButton.titleOfSelectedItem ?? "")")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getWordText(wordId: String, listId: String) -> String {
        guard let list = LLWordListStorage.shared.list(byId: listId),
              let entry = list.entries.first(where: { $0.id == wordId }) else {
            return "未知单词"
        }
        return entry.text
    }
    
    private func getWordInfo(wordId: String, listId: String) -> (text: String, meaning: String) {
        guard let list = LLWordListStorage.shared.list(byId: listId),
              let entry = list.entries.first(where: { $0.id == wordId }) else {
            return ("未知单词", "")
        }
        return (entry.text, entry.meaning)
    }
    
    private func getFeedbackIcon(feedback: LLWordFeedback) -> String {
        switch feedback {
        case .know:
            return "✔️"
        case .unclear:
            return "❓"
        case .unknown:
            return "❌"
        }
    }
    
    private func getFeedbackIconFromString(feedback: String) -> String {
        switch feedback {
        case "know":    return "✔️"
        case "unclear": return "❓"
        case "unknown": return "❌"
        default:        return "❓"
        }
    }
}

// MARK: - NSTableViewDataSource

extension LLProgressTabViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return wrongRecords.count
    }
}

// MARK: - NSTableViewDelegate

extension LLProgressTabViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < wrongRecords.count else { return nil }
        
        let record = wrongRecords[row]
        let columnId = tableColumn?.identifier.rawValue ?? ""
        
        let cellView = NSTableCellView()
        let textField = NSTextField(labelWithString: "")
        textField.isEditable = false
        textField.isBezeled = false
        textField.drawsBackground = false
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.textColor = LLAppearanceManager.shared.colors.primaryText
        
        cellView.addSubview(textField)
        textField.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
        }
        
        switch columnId {
        case "audio":
            // 创建按钮容器
            let buttonContainer = NSView()
            cellView.addSubview(buttonContainer)
            buttonContainer.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            
            // 美式发音按钮
            let usButton = NSButton(title: "🇺🇸", target: self, action: #selector(didClickPlayUS(_:)))
            usButton.bezelStyle = .rounded
            usButton.controlSize = .small
            usButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
            usButton.tag = row
            
            // 英式发音按钮
            let ukButton = NSButton(title: "🇬🇧", target: self, action: #selector(didClickPlayUK(_:)))
            ukButton.bezelStyle = .rounded
            ukButton.controlSize = .small
            ukButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
            ukButton.tag = row
            
            buttonContainer.addSubview(usButton)
            buttonContainer.addSubview(ukButton)
            
            usButton.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.width.equalTo(50)
                make.height.equalTo(20)
            }
            
            ukButton.snp.makeConstraints { make in
                make.top.equalTo(usButton.snp.bottom).offset(4)
                make.leading.trailing.bottom.equalToSuperview()
                make.width.equalTo(50)
                make.height.equalTo(20)
            }
            
            textField.removeFromSuperview()
            
        case "word":
            textField.stringValue = record.word
            textField.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
            
        case "meaning":
            textField.stringValue = record.meaning
            textField.lineBreakMode = .byTruncatingTail
            
        case "errorCount":
            textField.stringValue = "\(record.errorCount) 次"
            textField.alignment = .center
            textField.textColor = NSColor(srgbRed: 1.0, green: 0.23, blue: 0.19, alpha: 1)
            
        case "action":
            // 创建按钮容器
            let buttonContainer = NSView()
            cellView.addSubview(buttonContainer)
            buttonContainer.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            
            // 标记为已掌握按钮
            let markButton = NSButton(title: "✓ 已掌握", target: self, action: #selector(didClickMarkAsKnown(_:)))
            markButton.bezelStyle = .rounded
            markButton.controlSize = .small
            markButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
            markButton.tag = row
            markButton.wantsLayer = true
            markButton.layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.1).cgColor
            markButton.layer?.cornerRadius = 4
            markButton.contentTintColor = .systemGreen
            
            // 立即复习按钮
            let reviewButton = NSButton(title: "🔄 复习", target: self, action: #selector(didClickReview(_:)))
            reviewButton.bezelStyle = .rounded
            reviewButton.controlSize = .small
            reviewButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
            reviewButton.tag = row
            reviewButton.wantsLayer = true
            reviewButton.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1).cgColor
            reviewButton.layer?.cornerRadius = 4
            reviewButton.contentTintColor = .systemBlue
            
            buttonContainer.addSubview(markButton)
            buttonContainer.addSubview(reviewButton)
            
            markButton.snp.makeConstraints { make in
                make.leading.top.bottom.equalToSuperview()
                make.width.equalTo(65)
                make.height.equalTo(24)
            }
            
            reviewButton.snp.makeConstraints { make in
                make.leading.equalTo(markButton.snp.trailing).offset(8)
                make.trailing.top.bottom.equalToSuperview()
                make.width.equalTo(55)
                make.height.equalTo(24)
            }
            
            textField.removeFromSuperview()
            
        default:
            break
        }
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    @objc private func didClickMarkAsKnown(_ sender: NSButton) {
        let row = sender.tag
        guard row < wrongRecords.count else { return }
        
        let record = wrongRecords[row]
        markAsKnown(wordId: record.wordId, listId: record.listId)
    }
    
    @objc private func didClickReview(_ sender: NSButton) {
        let row = sender.tag
        guard row < wrongRecords.count else { return }
        
        let record = wrongRecords[row]
        reviewWord(wordId: record.wordId)
    }
    
    @objc private func didClickPlayUS(_ sender: NSButton) {
        let row = sender.tag
        guard row < wrongRecords.count else { return }
        let record = wrongRecords[row]
        
        LLLogger.debug("🔊 播放美式发音：\(record.word)")
        
        // 使用语音管理器播放美式发音
        LLPronunciationManager.shared.speak(word: record.word, accent: .us) { success, error in
            if let error = error {
                LLLogger.error("❌ 播放失败：\(error.localizedDescription)")
            } else if success {
                LLLogger.info("✅ 播放完成")
            }
        }
    }
    
    @objc private func didClickPlayUK(_ sender: NSButton) {
        let row = sender.tag
        guard row < wrongRecords.count else { return }
        let record = wrongRecords[row]
        
        LLLogger.debug("🔊 播放英式发音：\(record.word)")
        
        // 使用语音管理器播放英式发音
        LLPronunciationManager.shared.speak(word: record.word, accent: .uk) { success, error in
            if let error = error {
                LLLogger.error("❌ 播放失败：\(error.localizedDescription)")
            } else if success {
                LLLogger.info("✅ 播放完成")
            }
        }
    }
}
