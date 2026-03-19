//
//  LLTodayRecordContentView.swift
//  LearnLanguage
//
//  今日学习记录内容视图（基于 LLDBLearningHistory）
//  支持时间筛选，显示每个单词的学习次数

import AppKit

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
    
    private lazy var filterPopup: NSPopUpButton = {
        let popup = NSPopUpButton()
        for filter in LLTodayRecordTimeFilter.allCases {
            popup.addItem(withTitle: filter.displayName)
            popup.lastItem?.representedObject = filter
        }
        popup.target = self
        popup.action = #selector(filterChanged)
        popup.font = NSFont.systemFont(ofSize: 13)
        return popup
    }()
    
    private lazy var exportButton: NSButton = {
        let button = NSButton(title: NSLocalizedString("Export Stats", comment: ""), target: self, action: #selector(exportClicked))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor(srgbRed: 0.96, green: 0.96, blue: 0.97, alpha: 1).cgColor
        button.layer?.cornerRadius = 6
        button.layer?.borderWidth = 1
        button.layer?.borderColor = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.91, alpha: 1).cgColor
        button.contentTintColor = LLAppearanceManager.shared.colors.primaryText
        return button
    }()
    
    private lazy var countLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private let scrollView: NSScrollView = {
        let sv = NSScrollView()
        sv.hasVerticalScroller = true
        sv.hasHorizontalScroller = false
        sv.autohidesScrollers = true
        sv.borderType = .noBorder
        sv.drawsBackground = false
        return sv
    }()
    
    private let listView = _TodayRecordFlippedView()
    
    // MARK: - State
    
    var currentFilter: LLTodayRecordTimeFilter = .today
    var onExportClicked: (() -> Void)?
    
    // MARK: - Init
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        wantsLayer = true
        scrollView.documentView = listView
        addSubview(filterPopup)
        addSubview(exportButton)
        addSubview(countLabel)
        addSubview(scrollView)
    }
    
    // MARK: - Layout
    
    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }
        
        let toolbarH: CGFloat = 28
        let filterW: CGFloat = 120
        let btnW: CGFloat = 100
        let gap: CGFloat = 8
        
        filterPopup.frame  = NSRect(x: 0, y: h - toolbarH, width: filterW, height: toolbarH)
        exportButton.frame = NSRect(x: w - btnW, y: h - toolbarH, width: btnW, height: toolbarH)
        countLabel.frame   = NSRect(x: filterW + gap, y: h - toolbarH + 6, width: w - filterW - btnW - gap * 2, height: 16)
        
        let scrollY: CGFloat = 0
        scrollView.frame = NSRect(x: 0, y: scrollY, width: w, height: h - toolbarH - gap)
    }
    
    // MARK: - Public
    
    func updateItems(_ items: [LLTodayRecordItem]) {
        listView.subviews.forEach { $0.removeFromSuperview() }
        
        let itemH: CGFloat = 54
        let paddingV: CGFloat = 8
        let w = scrollView.bounds.width > 0 ? scrollView.bounds.width : bounds.width
        
        countLabel.stringValue = String(format: NSLocalizedString("Record Count %d", comment: ""), items.count)
        
        if items.isEmpty {
            let emptyLabel = NSTextField(labelWithString: NSLocalizedString("No Records Today", comment: ""))
            emptyLabel.font = NSFont.systemFont(ofSize: 14)
            emptyLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
            emptyLabel.isEditable = false
            emptyLabel.isBezeled = false
            emptyLabel.drawsBackground = false
            emptyLabel.alignment = .center
            emptyLabel.frame = NSRect(x: 0, y: paddingV, width: w, height: 50)
            listView.addSubview(emptyLabel)
            listView.frame = NSRect(x: 0, y: 0, width: w, height: 50 + paddingV * 2)
            return
        }
        
        let totalH = paddingV + CGFloat(items.count) * itemH + paddingV
        listView.frame = NSRect(x: 0, y: 0, width: w, height: totalH)
        
        for (index, item) in items.enumerated() {
            let itemView = LLTodayRecordItemView(
                item: item,
                showBorder: index < items.count - 1
            )
            itemView.frame = NSRect(x: 0, y: paddingV + CGFloat(index) * itemH, width: w, height: itemH)
            listView.addSubview(itemView)
        }
    }
    
    // MARK: - Actions
    
    @objc private func filterChanged() {
        if let filter = filterPopup.selectedItem?.representedObject as? LLTodayRecordTimeFilter {
            currentFilter = filter
            onFilterChanged?(filter)
        }
    }
    
    @objc private func exportClicked() {
        onExportClicked?()
    }
    
    var onFilterChanged: ((LLTodayRecordTimeFilter) -> Void)?
}

// MARK: - Item View

final class LLTodayRecordItemView: NSView {
    
    private let wordLabel: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        l.textColor = LLAppearanceManager.shared.colors.primaryText
        l.isEditable = false; l.isBezeled = false; l.drawsBackground = false
        return l
    }()
    
    private let timeLabel: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.font = NSFont.systemFont(ofSize: 12)
        l.textColor = LLAppearanceManager.shared.colors.secondaryText
        l.isEditable = false; l.isBezeled = false; l.drawsBackground = false
        return l
    }()
    
    private let countBadge: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        l.textColor = LLAppearanceManager.shared.colors.accentColor
        l.isEditable = false; l.isBezeled = false; l.drawsBackground = false
        l.alignment = .right
        return l
    }()
    
    private let feedbackLabel: NSTextField = {
        let l = NSTextField(labelWithString: "")
        l.font = NSFont.systemFont(ofSize: 18)
        l.isEditable = false; l.isBezeled = false; l.drawsBackground = false
        l.alignment = .right
        return l
    }()
    
    private let separator: NSView = {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.91, alpha: 1).cgColor
        return v
    }()
    
    private let showBorder: Bool
    
    init(item: LLTodayRecordItem, showBorder: Bool) {
        self.showBorder = showBorder
        super.init(frame: .zero)
        
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        
        wordLabel.stringValue = item.wordText
        timeLabel.stringValue = fmt.string(from: Date(timeIntervalSince1970: item.lastLearnedAt))
        countBadge.stringValue = String(format: NSLocalizedString("Times %d", comment: ""), item.learnCount)
        feedbackLabel.stringValue = feedbackIcon(item.lastFeedback)
        
        addSubview(wordLabel)
        addSubview(timeLabel)
        addSubview(countBadge)
        addSubview(feedbackLabel)
        if showBorder { addSubview(separator) }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }
        
        let rightW: CGFloat = 80
        let leftW = w - rightW - 12 - 12
        
        wordLabel.frame  = NSRect(x: 12, y: h / 2, width: leftW, height: 18)
        timeLabel.frame  = NSRect(x: 12, y: h / 2 - 18, width: leftW, height: 16)
        feedbackLabel.frame = NSRect(x: w - rightW - 12, y: (h - 24) / 2, width: 28, height: 24)
        countBadge.frame = NSRect(x: w - rightW - 12 + 30, y: (h - 16) / 2, width: rightW - 18, height: 16)
        
        if showBorder {
            separator.frame = NSRect(x: 12, y: 0, width: w - 12, height: 1)
        }
    }
    
    private func feedbackIcon(_ feedback: String) -> String {
        switch feedback {
        case "know":    return "✔️"
        case "unclear": return "❓"
        case "unknown": return "❌"
        default:        return "❓"
        }
    }
}

// MARK: - Flipped

private final class _TodayRecordFlippedView: NSView {
    override var isFlipped: Bool { true }
}
