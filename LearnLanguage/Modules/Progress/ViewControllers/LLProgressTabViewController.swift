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
        // 添加滚动视图
        wrongContentView.addSubview(wrongScrollView)
        wrongScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 创建内容容器
        let contentView = NSView()
        contentView.wantsLayer = true
        wrongScrollView.documentView = contentView
        
        // 关键：设置 contentView 的宽度约束
        contentView.snp.makeConstraints { make in
            make.width.equalTo(wrongScrollView)
        }
        
        // 使用新的 View 组件创建错题记录卡片
        wrongRecordCard = LLWrongRecordCardView()
        wrongRecordCard.onBatchReviewButtonClicked = { [weak self] in
            self?.batchReview()
        }
        contentView.addSubview(wrongRecordCard)
        wrongRecordCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(400)
            make.bottom.equalToSuperview().offset(-20)
        }
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
            print("开始批量复习错题")
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
                print("导出到: \(url.path)")
            }
        }
    }
    
    // MARK: - Data Loading
    
    @objc private func loadData() {
        guard isViewLoaded else { return }
        
        let listId = LLSettingsStore.shared.currentListId
        let store = LLLearningStore.shared
        
        // 获取统计数据
        let days = store.totalLearningDays(listId: listId)
        let (know, unclear, unknown) = store.feedbackCounts(listId: listId)
        let totalWords = know + unclear + unknown
        let todayCount = store.todayCount(listId: listId)
        
        // 使用新的 View 组件更新数据
        totalWordsCard?.updateNumber("\(totalWords)")
        streakCard?.updateNumber("\(days)")
        
        // 今日进度（假设目标是50个）
        let todayGoal = 50
        progressCard?.updateProgress(current: todayCount, total: todayGoal)
        
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
        
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let allRecords = LLLearningStore.shared.allRecords()
        let todayRecords = allRecords.filter { record in
            (listId == nil || record.listId == listId) && cal.isDate(record.lastSeenAt, inSameDayAs: today)
        }.sorted { $0.lastSeenAt > $1.lastSeenAt }
        
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
            let wordText = getWordText(wordId: record.wordId, listId: record.listId)
            let feedbackIcon = getFeedbackIcon(feedback: record.feedback)
            let itemView = LLRecordItemView(
                wordText: wordText,
                feedbackIcon: feedbackIcon,
                time: record.lastSeenAt,
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
        // 使用新的 View 组件获取滚动视图
        guard let scrollView = wrongRecordCard?.getScrollView() else { return }
        guard let listView = wrongRecordCard?.getListView() else { return }
        
        listView.subviews.forEach { $0.removeFromSuperview() }
        
        let allRecords = LLLearningStore.shared.allRecords()
        let wrongRecords = allRecords.filter { record in
            (listId == nil || record.listId == listId) && record.feedback == .unknown
        }.sorted { $0.lastSeenAt > $1.lastSeenAt }
        
        // 使用新的 View 组件更新错题数量
        wrongRecordCard?.updateCount(wrongRecords.count)
        
        if wrongRecords.isEmpty {
            let emptyLabel = NSTextField(labelWithString: "暂无错题记录，继续加油！")
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
        for (index, record) in wrongRecords.enumerated() {
            let (wordText, wordMean) = getWordInfo(wordId: record.wordId, listId: record.listId)
            let itemView = LLWrongRecordItemView(
                wordId: record.wordId,
                wordText: wordText,
                wordMean: wordMean,
                showBorder: index < wrongRecords.count - 1
            )
            itemView.onMarkAsKnown = { [weak self] wordId in
                self?.markAsKnown(wordId: wordId)
            }
            itemView.onReview = { [weak self] wordId in
                self?.reviewWord(wordId: wordId)
            }
            container.addSubview(itemView)
            itemView.snp.makeConstraints { make in
                if let last = lastView {
                    make.top.equalTo(last.snp.bottom)
                } else {
                    make.top.equalToSuperview().offset(8)
                }
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(60)
            }
            lastView = itemView
        }
        
        if let last = lastView {
            last.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-8)
            }
        }
    }
    
    @objc private func markAsKnown(wordId: String) {
        // TODO: 实现标记为已掌握的逻辑
        print("标记为已掌握: \(wordId)")
        loadData()
    }
    
    @objc private func reviewWord(wordId: String) {
        // TODO: 实现立即复习的逻辑
        print("立即复习: \(wordId)")
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
                print("✅ 已切换到词库: \(popUpButton.titleOfSelectedItem ?? "")")
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
}
