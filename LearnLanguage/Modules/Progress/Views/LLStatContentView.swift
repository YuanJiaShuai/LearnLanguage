//
//  LLStatContentView.swift
//  LearnLanguage
//
//  学习统计内容视图

import AppKit
import SnapKit

final class LLStatContentView: NSView {
    
    // MARK: - UI Components
    
    private lazy var scrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.backgroundColor = NSColor.clear
        return scroll
    }()
    
    private var currentListCard: LLCurrentListCardView!
    private var totalWordsCard: LLStatCardView!
    private var progressCard: LLProgressCardView!
    private var streakCard: LLStatCardView!
    private var trendCard: LLTrendCardView!
    private var todayRecordCard: LLTodayRecordCardView!
    
    // MARK: - Callbacks
    
    var onChangeWordListClicked: (() -> Void)?
    var onExportRecordsClicked: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        wantsLayer = true
        
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 创建内容容器
        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.layer?.backgroundColor = NSColor.red.cgColor
        scrollView.documentView = contentView
        
        contentView.snp.makeConstraints { make in
            make.width.equalTo(scrollView)
            make.left.top.right.bottom.equalToSuperview()
        }
        
        // 当前学习词库卡片
        currentListCard = LLCurrentListCardView()
        currentListCard.onChangeButtonClicked = { [weak self] in
            self?.onChangeWordListClicked?()
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
            self?.onExportRecordsClicked?()
        }
        contentView.addSubview(todayRecordCard)
        todayRecordCard.snp.makeConstraints { make in
            make.top.equalTo(trendCard.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.greaterThanOrEqualTo(300)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    // MARK: - Public Methods
    
    func updateStatistics(totalWords: Int, days: Int, todayCount: Int, todayGoal: Int) {
        totalWordsCard?.updateNumber("\(totalWords)")
        streakCard?.updateNumber("\(days)")
        progressCard?.updateProgress(current: todayCount, total: todayGoal)
    }
    
    func updateTodayRecords(_ records: [LLDBLearningProgress]) {
        guard let scrollView = todayRecordCard?.getScrollView() else { return }
        guard let listView = todayRecordCard?.getListView() else { return }
        
        listView.subviews.forEach { $0.removeFromSuperview() }
        
        if records.isEmpty {
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
        for (index, record) in records.prefix(20).enumerated() {
            let wordText = getWordText(wordId: record.wordId ?? "", listId: record.wordListId ?? "")
            let feedbackIcon = getFeedbackIconFromString(feedback: record.lastFeedback ?? "")
            let itemView = LLRecordItemView(
                wordText: wordText,
                feedbackIcon: feedbackIcon,
                time: Date(timeIntervalSince1970: record.lastSeenAt ?? 0),
                showBorder: index < records.count - 1
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
    
    // MARK: - Helper Methods
    
    private func getWordText(wordId: String, listId: String) -> String {
        guard let list = LLWordListStorage.shared.list(byId: listId),
              let entry = list.entries.first(where: { $0.id == wordId }) else {
            return "未知单词"
        }
        return entry.text
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
