//
//  LLReviewContentView.swift
//  LearnLanguage
//
//  复习记录内容视图

import AppKit
import SnapKit

final class LLReviewContentView: NSView {
    
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
    
    enum TimeFilter: String, CaseIterable {
        case all = "全部"
        case today = "今天"
        case week = "本周"
        case month = "本月"
    }
    
    var currentTimeFilter: TimeFilter = .all {
        didSet {
            onTimeFilterChanged?(currentTimeFilter.rawValue)
        }
    }
    
    var records: [LLDBLearningProgress] = [] {
        didSet {
            tableView?.reloadData()
        }
    }
    
    var onTimeFilterChanged: ((String) -> Void)?
    var onMarkAsKnown: ((String, String) -> Void)?
    var onReviewWord: ((String) -> Void)?
    var onPlayUS: ((String, String) -> Void)?
    var onPlayUK: ((String, String) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        wantsLayer = true
        
        addSubview(toolbar)
        toolbar.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(40)
        }
        
        let filterLabel = NSTextField(labelWithString: "时间范围：")
        filterLabel.font = NSFont.systemFont(ofSize: 13)
        filterLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        toolbar.addSubview(filterLabel)
        filterLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        let popup = NSPopUpButton()
        popup.bezelStyle = .rounded
        popup.font = NSFont.systemFont(ofSize: 13)
        TimeFilter.allCases.forEach { popup.addItem(withTitle: $0.rawValue) }
        popup.target = self
        popup.action = #selector(timeFilterChanged(_:))
        toolbar.addSubview(popup)
        popup.snp.makeConstraints { make in
            make.leading.equalTo(filterLabel.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
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
        tableView.selectionHighlightStyle = .regular
        
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
        let columns = [
            ("audio", "发音", 70, 60),
            ("word", "单词", 130, 100),
            ("meaning", "释义", 180, 150),
            ("errorCount", "错误次数", 90, 80),
            ("action", "操作", 140, 120)
        ]
        
        for (id, title, width, minWidth) in columns {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(id))
            column.title = title
            column.width = CGFloat(width)
            column.minWidth = CGFloat(minWidth)
            tableView.addTableColumn(column)
        }
    }
    
    @objc private func timeFilterChanged(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        guard index >= 0 && index < TimeFilter.allCases.count else { return }
        currentTimeFilter = TimeFilter.allCases[index]
    }
}

extension LLReviewContentView: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return records.count
    }
}

extension LLReviewContentView: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < records.count else { return nil }
        
        let record = records[row]
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
            setupAudioCell(cellView, textField, row)
        case "word":
            textField.stringValue = getWordText(wordId: record.wordId ?? "", listId: record.wordListId ?? "")
            textField.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        case "meaning":
            textField.stringValue = getWordMeaning(wordId: record.wordId ?? "", listId: record.wordListId ?? "")
            textField.lineBreakMode = .byTruncatingTail
        case "errorCount":
            textField.stringValue = "\(record.reviewCount ?? 0) 次"
            textField.alignment = .center
            textField.textColor = NSColor(srgbRed: 1.0, green: 0.23, blue: 0.19, alpha: 1)
        case "action":
            setupActionCell(cellView, textField, row)
        default:
            break
        }
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    private func setupAudioCell(_ cellView: NSTableCellView, _ textField: NSTextField, _ row: Int) {
        let buttonContainer = NSView()
        cellView.addSubview(buttonContainer)
        buttonContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        let usButton = NSButton(title: "🇺🇸", target: self, action: #selector(didClickPlayUS(_:)))
        usButton.bezelStyle = .rounded
        usButton.controlSize = .small
        usButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        usButton.tag = row
        
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
    }
    
    private func setupActionCell(_ cellView: NSTableCellView, _ textField: NSTextField, _ row: Int) {
        let buttonContainer = NSView()
        cellView.addSubview(buttonContainer)
        buttonContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        let markButton = NSButton(title: "✓ 已掌握", target: self, action: #selector(didClickMarkAsKnown(_:)))
        markButton.bezelStyle = .rounded
        markButton.controlSize = .small
        markButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        markButton.tag = row
        markButton.wantsLayer = true
        markButton.layer?.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.1).cgColor
        markButton.layer?.cornerRadius = 4
        markButton.contentTintColor = .systemGreen
        
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
    }
    
    @objc private func didClickMarkAsKnown(_ sender: NSButton) {
        let row = sender.tag
        guard row < records.count else { return }
        let record = records[row]
        onMarkAsKnown?(record.wordId ?? "", record.wordListId ?? "")
    }
    
    @objc private func didClickReview(_ sender: NSButton) {
        let row = sender.tag
        guard row < records.count else { return }
        let record = records[row]
        onReviewWord?(record.wordId ?? "")
    }
    
    @objc private func didClickPlayUS(_ sender: NSButton) {
        let row = sender.tag
        guard row < records.count else { return }
        let record = records[row]
        let word = getWordText(wordId: record.wordId ?? "", listId: record.wordListId ?? "")
        onPlayUS?(word, record.wordListId ?? "")
    }
    
    @objc private func didClickPlayUK(_ sender: NSButton) {
        let row = sender.tag
        guard row < records.count else { return }
        let record = records[row]
        let word = getWordText(wordId: record.wordId ?? "", listId: record.wordListId ?? "")
        onPlayUK?(word, record.wordListId ?? "")
    }
    
    private func getWordText(wordId: String, listId: String) -> String {
        guard let list = LLWordListStorage.shared.list(byId: listId),
              let entry = list.entries.first(where: { $0.id == wordId }) else {
            return "未知单词"
        }
        return entry.text
    }
    
    private func getWordMeaning(wordId: String, listId: String) -> String {
        guard let list = LLWordListStorage.shared.list(byId: listId),
              let entry = list.entries.first(where: { $0.id == wordId }) else {
            return ""
        }
        return entry.meaning
    }
}
