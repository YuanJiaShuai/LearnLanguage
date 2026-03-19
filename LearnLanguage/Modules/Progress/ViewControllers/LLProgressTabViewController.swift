//
//  LLProgressTabViewController.swift
//  LearnLanguage
//
//  学习记录模块 - 包含学习统计和错题记录两个子标签

import AppKit
import SnapKit
import UniformTypeIdentifiers

final class LLProgressTabViewController: NSViewController {

    // MARK: - Type Aliases
    
    typealias TimeFilter = LLReviewContentView.TimeFilter
    
    // 页面标题
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Progress Module Title", comment: ""))
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
        let button = NSButton(title: NSLocalizedString("Stat Tab", comment: ""), target: self, action: #selector(switchToStatTab))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        return button
    }()
    
    private lazy var reviewTabButton: NSButton = {
        let button = NSButton(title: NSLocalizedString("Review Tab", comment: ""), target: self, action: #selector(switchToreviewTab))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        button.wantsLayer = true
        button.layer?.cornerRadius = 6
        return button
    }()
    
    // 学习统计页面容器
    private lazy var statContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        return view
    }()
    
    // 复习记录页面容器
    private lazy var reviewContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.isHidden = true
        return view
    }()
    
    // 内容视图
    private var statContentView: LLStatContentView!
    private var reviewContentView: LLReviewContentView!
    
    // 当前选中的标签
    private enum Tab {
        case stat
        case review
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
        
        tabContainer.addSubview(reviewTabButton)
        reviewTabButton.snp.makeConstraints { make in
            make.leading.equalTo(statTabButton.snp.trailing).offset(4)
            make.top.bottom.trailing.equalToSuperview()
            make.width.greaterThanOrEqualTo(80)
        }
        
        // 添加学习统计页面
        view.addSubview(statContainer)
        statContainer.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(28)
            make.bottom.equalToSuperview().offset(-28)
        }
        
        statContentView = LLStatContentView()
        statContentView.onChangeWordListClicked = { [weak self] in
            self?.showWordListSelector()
        }
        statContentView.onExportRecordsClicked = { [weak self] in
            self?.exportRecords()
        }
        statContainer.addSubview(statContentView)
        statContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 添加复习记录页面
        view.addSubview(reviewContainer)
        reviewContainer.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(28)
            make.bottom.equalToSuperview().offset(-28)
        }
        
        reviewContentView = LLReviewContentView()
        reviewContentView.onTimeFilterChanged = { [weak self] _ in
            self?.resetReviewPagination()
            self?.loadReviewRecords(listId: LLSettingsStore.shared.currentListId)
        }
        reviewContentView.onMarkAsKnown = { [weak self] wordId, listId in
            self?.markAsKnown(wordId: wordId, listId: listId)
        }
        reviewContentView.onReviewWord = { [weak self] wordId in
            self?.reviewWord(wordId: wordId)
        }
        reviewContentView.onPlayUS = { [weak self] word, listId in
            self?.playPronunciation(word: word, accent: .us)
        }
        reviewContentView.onPlayUK = { [weak self] word, listId in
            self?.playPronunciation(word: word, accent: .uk)
        }
        reviewContentView.onPlayPronunciation = { [weak self] word, listId in
            // 根据设置选择发音方式
            LLLogger.info("📢 点击了行，单词: \(word)")
            let accent = LLSettingsStore.shared.settings.pronunciationAccent
            self?.playPronunciation(word: word, accent: accent)
        }
        reviewContainer.addSubview(reviewContentView)
        reviewContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 默认选中学习统计
        updateTabButtonStyles()
    }
    
    @objc private func switchToStatTab() {
        currentTab = .stat
        updateTabButtonStyles()
        statContainer.isHidden = false
        reviewContainer.isHidden = true
    }
    
    @objc private func switchToreviewTab() {
        currentTab = .review
        updateTabButtonStyles()
        statContainer.isHidden = true
        reviewContainer.isHidden = false
    }
    
    private func updateTabButtonStyles() {
        let activeColor = LLAppearanceManager.shared.colors.accentColor
        let inactiveColor = NSColor(srgbRed: 0.96, green: 0.96, blue: 0.97, alpha: 1)
        
        statTabButton.wantsLayer = true
        reviewTabButton.wantsLayer = true
        
        if currentTab == .stat {
            statTabButton.layer?.backgroundColor = activeColor.cgColor
            statTabButton.contentTintColor = .white
            reviewTabButton.layer?.backgroundColor = inactiveColor.cgColor
            reviewTabButton.contentTintColor = LLAppearanceManager.shared.colors.primaryText
        } else {
            statTabButton.layer?.backgroundColor = inactiveColor.cgColor
            statTabButton.contentTintColor = LLAppearanceManager.shared.colors.primaryText
            reviewTabButton.layer?.backgroundColor = activeColor.cgColor
            reviewTabButton.contentTintColor = .white
        }
    }
    

    
    @objc private func exportRecords() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "学习记录_\(Date().timeIntervalSince1970).json"
        savePanel.message = NSLocalizedString("Export Records Message", comment: "")
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                // TODO: 实现导出逻辑
                LLLogger.info("导出到: \(url.path)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    func switchToReviewTab() {
        switchToreviewTab()
    }
    
    func setTimeFilter(to filter: TimeFilter) {
        reviewContentView?.currentTimeFilter = filter
        
        // 更新下拉框的选中项
        if let reviewView = reviewContentView {
            // 找到对应的下拉框并更新
            for subview in reviewView.subviews {
                if let popup = findPopupButton(in: subview) {
                    let index = TimeFilter.allCases.firstIndex(of: filter) ?? 0
                    popup.selectItem(at: index)
                    break
                }
            }
        }
        
        resetReviewPagination()
        loadReviewRecords(listId: LLSettingsStore.shared.currentListId)
    }
    
    private func findPopupButton(in view: NSView) -> NSPopUpButton? {
        if let popup = view as? NSPopUpButton {
            return popup
        }
        for subview in view.subviews {
            if let popup = findPopupButton(in: subview) {
                return popup
            }
        }
        return nil
    }
    
    @objc private func loadData() {
        guard isViewLoaded else { return }
        
        let listId = LLSettingsStore.shared.currentListId
        
        do {
            let todayCount = try LLDatabaseManager.shared.getTodayLearnedCount(wordListId: listId)
            let stats: (total: Int, learned: Int, mastered: Int, learning: Int)
            if let listId = listId {
                stats = try LLDatabaseManager.shared.getWordListProgressStats(wordListId: listId)
            } else {
                stats = (0, 0, 0, 0)
            }
            let totalWords = stats.learned
            let days = LLLearningStore.shared.totalLearningDays(listId: listId)
            
            statContentView?.updateStatistics(totalWords: totalWords, days: days, todayCount: todayCount, todayGoal: LLSettingsStore.shared.settings.newWordsPerDay)
        } catch {
            LLLogger.error("❌ 加载统计数据失败：\(error)")
        }
        
        loadTodayRecords(listId: listId)
        loadReviewRecords(listId: listId)
    }
    
    private func loadTodayRecords(listId: String?) {
        do {
            let allProgress = try LLDatabaseManager.shared.getAllLearningProgress(wordListId: listId ?? "")
            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            let todayRecords = allProgress.filter { record in
                let date = Date(timeIntervalSince1970: record.lastSeenAt ?? 0)
                return cal.isDate(date, inSameDayAs: today)
            }.sorted { ($0.lastSeenAt ?? 0) > ($1.lastSeenAt ?? 0) }
            
            statContentView?.updateTodayRecords(todayRecords)
        } catch {
            LLLogger.error("❌ 加载今日学习记录失败：\(error)")
        }
    }
    
    // MARK: - 分页相关
    
    private var reviewPageSize = 20
    private var reviewCurrentPage = 0
    
    private func loadReviewRecords(listId: String?) {
        LLLogger.info("📊 开始加载复习记录，页码: \(reviewCurrentPage)")
        
        do {
            let records: [LLDBLearningProgress]
            let timeFilter = reviewContentView?.currentTimeFilter ?? .all
            
            LLLogger.info("📋 时间筛选: \(timeFilter.rawValue)")
            
            // 先获取所有符合条件的记录（不限制词库）
            let allRecords: [LLDBLearningProgress]
            switch timeFilter {
            case .all:
                allRecords = try LLDatabaseManager.shared.getAllReviewRecords()
            case .today:
                allRecords = try LLDatabaseManager.shared.getTodayReviewRecords()
            case .week:
                allRecords = try LLDatabaseManager.shared.getWeekReviewRecords()
            case .month:
                allRecords = try LLDatabaseManager.shared.getMonthReviewRecords()
            }
            
            LLLogger.info("📊 查询到 \(allRecords.count) 条复习记录")
            
            // 分页处理
            let startIndex = reviewCurrentPage * reviewPageSize
            let endIndex = min(startIndex + reviewPageSize, allRecords.count)
            
            if startIndex < allRecords.count {
                records = Array(allRecords[startIndex..<endIndex])
                LLLogger.info("📄 第 \(reviewCurrentPage + 1) 页，显示 \(records.count) 条记录（总共 \(allRecords.count) 条）")
            } else {
                records = []
                LLLogger.info("⚠️ 页码超出范围")
            }
            
            // 打印前几条记录的详情
            for (index, record) in records.prefix(3).enumerated() {
                LLLogger.info("  [\(index)] wordId: \(record.wordId ?? "nil"), learnCount: \(record.learnCount ?? 0), status: \(record.status ?? 0)")
            }
            
            reviewContentView?.records = records
        } catch {
            LLLogger.error("❌ 加载复习记录失败：\(error)")
            reviewContentView?.records = []
        }
    }
    
    // 重置分页
    private func resetReviewPagination() {
        reviewCurrentPage = 0
    }
    
    // 下一页
    private func loadNextReviewPage() {
        reviewCurrentPage += 1
        loadReviewRecords(listId: LLSettingsStore.shared.currentListId)
    }
    
    // 上一页
    private func loadPreviousReviewPage() {
        reviewCurrentPage = max(0, reviewCurrentPage - 1)
        loadReviewRecords(listId: LLSettingsStore.shared.currentListId)
    }
    
    @objc private func markAsKnown(wordId: String, listId: String) {
        do {
            guard let record = try LLDatabaseManager.shared.getLearningProgress(wordId: wordId, wordListId: listId) else {
                return
            }
            
            record.reviewCount = 0
            record.status = 2
            record.updatedAt = Date().timeIntervalSince1970
            
            try LLDatabaseManager.shared.recordLearningProgress(
                wordId: wordId,
                wordListId: listId,
                feedback: "know"
            )
            
            LLLogger.info("✅ 已标记为已掌握: \(wordId)")
            loadData()
        } catch {
            LLLogger.error("❌ 标记失败：\(error)")
        }
    }
    
    @objc private func reviewWord(wordId: String) {
        LLLogger.info("立即复习: \(wordId)")
    }
    
    private func playPronunciation(word: String, accent: LLPronunciationAccent) {
        let accentName = accent == .us ? "美式" : "英式"
        LLLogger.debug("🔊 播放\(accentName)发音：\(word)")
        
        LLPronunciationManager.shared.speak(word: word, accent: accent) { success, error in
            if let error = error {
                LLLogger.error("❌ 播放失败：\(error.localizedDescription)")
            } else if success {
                LLLogger.info("✅ 播放完成")
            }
        }
    }
    
    private func showWordListSelector() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Select List", comment: "")
        alert.informativeText = NSLocalizedString("Select List Desc", comment: "")
        
        // 获取所有词库
        let allLists = LLWordListStorage.shared.allLists()
        
        if allLists.isEmpty {
            alert.informativeText = NSLocalizedString("No Word List", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
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
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        
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
            return NSLocalizedString("Unknown Word", comment: "")
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
