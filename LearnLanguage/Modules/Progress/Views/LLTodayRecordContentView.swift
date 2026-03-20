//
//  LLTodayRecordContentView.swift
//  LearnLanguage
//
//  今日学习记录内容视图（基于 LLDBLearningHistory）
//  支持时间筛选，显示每个单词的学习次数

import AppKit
import SnapKit

// MARK: - 聚合数据结构

/// 按单词聚合后的学习记录
struct LLTodayRecordItem {
    let wordId: String
    let wordListId: String
    let wordText: String
    let lastFeedback: String   // 最后一次反馈
    let learnCount: Int        // 今日学习次数
    let lastLearnedAt: TimeInterval
}

// MARK: - 时间筛选

enum LLTodayRecordTimeFilter: String, CaseIterable {
    case today = "today"
    case week  = "week"
    case month = "month"
    case all   = "all"
    
    var displayName: String {
        switch self {
        case .today: return NSLocalizedString("Filter Today", comment: "")
        case .week:  return NSLocalizedString("Filter Week", comment: "")
        case .month: return NSLocalizedString("Filter Month", comment: "")
        case .all:   return NSLocalizedString("Filter All", comment: "")
        }
    }
}

// MARK: - View

final class LLTodayRecordContentView: NSView {
    
    // MARK: - UI
    
    private lazy var toolbar: NSView = {
        let view = NSView()
        view.wantsLayer = true
        return view
    }()
    
    private lazy var tableContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
        view.layer?.cornerRadius = 8
        view.layer?.borderWidth = 1
        view.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        return view
    }()
    
    private lazy var scrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        return scroll
    }()
    
    private var tableView: NSTableView!
    
    // MARK: - State
    
    var currentFilter: LLTodayRecordTimeFilter = .today {
        didSet { onFilterChanged?(currentFilter) }
    }
    
    var items: [LLTodayRecordItem] = [] {
        didSet { tableView?.reloadData() }
    }
    
    var onExportClicked: (() -> Void)?
    var onFilterChanged: ((LLTodayRecordTimeFilter) -> Void)?
    var onPlayPronunciation: ((String, String) -> Void)?
    
    // MARK: - Init
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        
        addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(40)
        }
        
        let filterLabel = NSTextField(labelWithString: NSLocalizedString("Time Range", comment: ""))
        filterLabel.font = NSFont.systemFont(ofSize: 13)
        filterLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        toolbar.addSubview(filterLabel)
        filterLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        let popup = NSPopUpButton()
        popup.bezelStyle = .rounded
        popup.font = NSFont.systemFont(ofSize: 13)
        LLTodayRecordTimeFilter.allCases.forEach { popup.addItem(withTitle: $0.displayName) }
        popup.target = self
        popup.action = #selector(filterChanged(_:))
        toolbar.addSubview(popup)
        popup.snp.makeConstraints { make in
            make.leading.equalTo(filterLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.width.equalTo(100)
        }
        
        let exportButton = NSButton(title: NSLocalizedString("Export Stats", comment: ""), target: self, action: #selector(exportClicked))
        exportButton.bezelStyle = .rounded
        toolbar.addSubview(exportButton)
        exportButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.width.equalTo(100)
        }
        
        addSubview(tableContainer)
        tableContainer.snp.makeConstraints { make in
            make.top.equalTo(toolbar.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }
        
        tableView = NSTableView()
        tableView.style = .fullWidth
        tableView.rowHeight = 60
        tableView.backgroundColor = .clear
        tableView.gridStyleMask = [.solidHorizontalGridLineMask]
        tableView.gridColor = LLAppearanceManager.shared.colors.borderColor
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.selectionHighlightStyle = .none
        tableView.allowsEmptySelection = true
        tableView.allowsMultipleSelection = false
        
        setupTableColumns()
        tableView.delegate = self
        tableView.dataSource = self
        
        scrollView.documentView = tableView
        tableContainer.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
    }
    
    private func setupTableColumns() {
        let columns: [(String, String, CGFloat, CGFloat)] = [
            ("play",     NSLocalizedString("Play", comment: ""),        50,  50),
            ("word",     NSLocalizedString("Word", comment: ""),        130, 100),
            ("time",     NSLocalizedString("Time", comment: ""),        160, 130),
            ("count",    NSLocalizedString("Times", comment: ""),       80,  60),
            ("feedback", NSLocalizedString("Status", comment: ""),      60,  50)
        ]
        
        for (id, title, width, minWidth) in columns {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = width
            column.minWidth = minWidth
            tableView.addTableColumn(column)
        }
    }
    
    // MARK: - Actions
    
    @objc private func filterChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        guard index >= 0 && index < LLTodayRecordTimeFilter.allCases.count else { return }
        currentFilter = LLTodayRecordTimeFilter.allCases[index]
    }
    
    @objc private func exportClicked() {
        onExportClicked?()
    }
    
    // MARK: - Public
    
    func updateItems(_ newItems: [LLTodayRecordItem]) {
        items = newItems
    }
}

// MARK: - NSTableViewDataSource

extension LLTodayRecordContentView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return items.count
    }
}

// MARK: - NSTableViewDelegate

extension LLTodayRecordContentView: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < items.count else { return nil }
        
        let item = items[row]
        let columnId = tableColumn?.identifier.rawValue ?? ""
        
        let cellView = NSTableCellView()
        cellView.wantsLayer = true
        
        switch columnId {
        case "play":
            let playButton = NSButton(title: "🔊", target: self, action: #selector(didClickPlayButton(_:)))
            playButton.bezelStyle = .rounded
            playButton.controlSize = .small
            playButton.font = NSFont.systemFont(ofSize: 14, weight: .medium)
            playButton.tag = row
            cellView.addSubview(playButton)
            playButton.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(30)
            }
            
        case "word":
            let container = NSView()
            cellView.addSubview(container)
            container.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(8)
                make.centerY.equalToSuperview()
            }
            let wordLabel = NSTextField(labelWithString: item.wordText)
            wordLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
            wordLabel.textColor = LLAppearanceManager.shared.colors.primaryText
            container.addSubview(wordLabel)
            wordLabel.snp.makeConstraints { make in
                make.top.leading.trailing.equalToSuperview()
                make.height.equalTo(18)
            }
            let phoneticLabel = NSTextField(labelWithString: getPhonetic(wordId: item.wordId, listId: item.wordListId))
            phoneticLabel.font = NSFont.systemFont(ofSize: 11)
            phoneticLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
            container.addSubview(phoneticLabel)
            phoneticLabel.snp.makeConstraints { make in
                make.top.equalTo(wordLabel.snp.bottom).offset(2)
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(14)
            }
            
        case "time":
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd HH:mm"
            let label = makeLabel(fmt.string(from: Date(timeIntervalSince1970: item.lastLearnedAt)))
            cellView.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(8)
                make.trailing.equalToSuperview().offset(-8)
                make.centerY.equalToSuperview()
            }
            
        case "count":
            let label = makeLabel(String(format: NSLocalizedString("Times %d", comment: ""), item.learnCount))
            label.textColor = LLAppearanceManager.shared.colors.accentColor
            cellView.addSubview(label)
            label.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(8)
                make.trailing.equalToSuperview().offset(-8)
                make.centerY.equalToSuperview()
            }
            
        case "feedback":
            let label = makeLabel(feedbackIcon(item.lastFeedback))
            label.font = NSFont.systemFont(ofSize: 16)
            cellView.addSubview(label)
            label.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            
        default:
            break
        }
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool { true }
    
    func tableView(_ tableView: NSTableView, didSelectRowAt rowIndexSet: IndexSet) {
        guard let row = rowIndexSet.first, row < items.count else { return }
        let item = items[row]
        onPlayPronunciation?(item.wordText, item.wordListId)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            tableView.deselectRow(row)
        }
    }
    
    @objc private func didClickPlayButton(_ sender: NSButton) {
        let row = sender.tag
        guard row < items.count else { return }
        let item = items[row]
        onPlayPronunciation?(item.wordText, item.wordListId)
    }
    
    // MARK: - Helpers
    
    private func makeLabel(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.isEditable = false
        l.isBezeled = false
        l.drawsBackground = false
        l.font = NSFont.systemFont(ofSize: 13)
        l.textColor = LLAppearanceManager.shared.colors.primaryText
        return l
    }
    
    private func feedbackIcon(_ feedback: String) -> String {
        switch feedback {
        case "know":    return "✔️"
        case "unclear": return "❓"
        case "unknown": return "❌"
        default:        return "❓"
        }
    }
    
    private func getPhonetic(wordId: String, listId: String) -> String {
        guard let list = LLWordListStorage.shared.list(byId: listId),
              let entry = list.entries.first(where: { $0.id == wordId }),
              let phonetic = entry.phonetic, !phonetic.isEmpty else { return "" }
        return phonetic
    }
}
