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
    
    private lazy var reviewTabButton: NSButton = {
        let button = NSButton(title: "复习记录", target: self, action: #selector(switchToreviewTab))
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
    
    // 错题记录页面容器
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
        
        // 添加错题记录页面
        view.addSubview(reviewContainer)
        reviewContainer.snp.makeConstraints { make in
            make.top.equalTo(tabContainer.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(28)
            make.bottom.equalToSuperview().offset(-28)
        }
        
        reviewContentView = LLReviewContentView()
        reviewContentView.onTimeFilterChanged = { [weak self] _ in
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
            
            statContentView?.updateStatistics(totalWords: totalWords, days: days, todayCount: todayCount, todayGoal: 50)
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
    
    private func loadReviewRecords(listId: String?) {
        guard let listId = listId else {
            reviewContentView?.records = []
            return
        }
        
        do {
            let records: [LLDBLearningProgress]
            let timeFilter = reviewContentView?.currentTimeFilter ?? .all
            switch timeFilter {
            case .all:
                records = try LLDatabaseManager.shared.getAllReviewRecords(wordListId: listId)
            case .today:
                records = try LLDatabaseManager.shared.getTodayReviewRecords(wordListId: listId)
            case .week:
                records = try LLDatabaseManager.shared.getWeekReviewRecords(wordListId: listId)
            case .month:
                records = try LLDatabaseManager.shared.getMonthReviewRecords(wordListId: listId)
            }
            
            LLLogger.info("✅ 加载了 \(records.count) 条复习记录")
            reviewContentView?.records = records
        } catch {
            LLLogger.error("❌ 加载复习记录失败：\(error)")
            reviewContentView?.records = []
        }
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
