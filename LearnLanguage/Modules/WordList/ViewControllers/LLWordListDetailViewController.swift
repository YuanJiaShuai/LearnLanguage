//
//  LLWordListDetailViewController.swift
//  LearnLanguage
//
//  词库详情页面 - 显示词库中的所有单词

import AppKit
import SnapKit

final class LLWordListDetailViewController: NSViewController {
    
    // MARK: - UI Components
    
    // 返回按钮
    private lazy var backButton: NSButton = {
        let button = NSButton(title: "返回", target: self, action: #selector(didClickBack))
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: nil)
        button.imagePosition = .imageLeading
        button.image?.isTemplate = true
        return button
    }()
    
    // 词库标题
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.moduleTitleText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    // 统计信息标签
    private lazy var statsLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    // 搜索框
    private lazy var searchField: NSSearchField = {
        let field = NSSearchField()
        field.placeholderString = "搜索单词..."
        field.target = self
        field.action = #selector(onSearchChanged)
        return field
    }()
    
    // 开始学习/继续学习按钮
    private lazy var startLearningButton: NSButton = {
        let button = NSButton(title: "开始学习", target: self, action: #selector(didClickStartLearning))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        button.contentTintColor = .white
        
        // 设置按钮背景色
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.systemBlue.cgColor
        button.layer?.cornerRadius = 6
        
        return button
    }()
    
    // 主内容容器
    private lazy var contentContainerView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
        view.layer?.cornerRadius = 8
        view.layer?.borderWidth = 1
        view.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        return view
    }()
    
    // TableView 滚动容器
    private lazy var tableScrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = tableView
        return scrollView
    }()
    
    // TableView
    private lazy var tableView: NSTableView = {
        let table = NSTableView()
        table.style = .fullWidth
        table.rowHeight = 80  // 增加行高以容纳按钮
        table.backgroundColor = .clear
        table.gridStyleMask = [.solidHorizontalGridLineMask]
        table.gridColor = LLAppearanceManager.shared.colors.borderColor
        table.headerView = nil
        table.usesAlternatingRowBackgroundColors = false
        table.selectionHighlightStyle = .regular
        
        // 添加一个完整的列来显示所有内容
        let mainColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("main"))
        mainColumn.title = ""
        table.addTableColumn(mainColumn)
        
        table.delegate = self
        table.dataSource = self
        
        return table
    }()
    
    // MARK: - Data
    
    private var wordListId: String
    private var wordListName: String
    private var allWords: [LLDBWord] = []
    private var filteredWords: [LLDBWord] = []
    
    // MARK: - Lifecycle
    
    init(wordListId: String, wordListName: String) {
        self.wordListId = wordListId
        self.wordListName = wordListName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadWords()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.mainBackground.cgColor
        
        // 1. 添加返回按钮
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.top.equalToSuperview().offset(28)
            make.height.equalTo(32)
        }
        
        // 2. 添加标题
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(16)
            make.centerY.equalTo(backButton)
        }
        
        // 3. 添加统计信息
        view.addSubview(statsLabel)
        statsLabel.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(12)
            make.centerY.equalTo(titleLabel)
        }
        
        // 4. 添加开始学习按钮
        view.addSubview(startLearningButton)
        startLearningButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-28)
            make.centerY.equalTo(backButton)
            make.width.equalTo(120)
            make.height.equalTo(36)
        }
        
        // 5. 添加搜索框
        view.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.right.equalTo(startLearningButton.snp.left).offset(-12)
            make.centerY.equalTo(backButton)
            make.width.equalTo(200)
            make.height.equalTo(28)
        }
        
        // 6. 添加主内容容器
        view.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.right.equalToSuperview().offset(-28)
            make.top.equalTo(backButton.snp.bottom).offset(24)
            make.bottom.equalToSuperview().offset(-28)
        }
        
        // 7. 添加 TableView
        contentContainerView.addSubview(tableScrollView)
        tableScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
    }
    
    // MARK: - Data Loading
    
    private func loadWords() {
        guard let listId = Int(wordListId) else {
            LLLogger.error("❌ 无效的词库 ID：\(wordListId)")
            return
        }
        
        do {
            // 从数据库加载单词
            allWords = try LLDatabaseManager.shared.getWords(forWordListId: listId)
            filteredWords = allWords
            
            LLLogger.info("✅ 加载了 \(allWords.count) 个单词")
            
            // 更新标题和统计信息
            titleLabel.stringValue = wordListName
            updateStatsLabel()
            
            // 更新学习按钮文字
            updateLearningButtonTitle()
            
            // 刷新表格
            tableView.reloadData()
            
        } catch {
            LLLogger.error("❌ 加载单词失败：\(error)")
            
            // 显示错误提示
            let alert = NSAlert()
            alert.messageText = "加载失败"
            alert.informativeText = "无法加载词库单词：\(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "确定")
            alert.runModal()
        }
    }
    
    private func updateStatsLabel() {
        let learnedCount = allWords.filter { $0.isLearned }.count
        statsLabel.stringValue = "共 \(allWords.count) 个单词，已学习 \(learnedCount) 个"
    }
    
    private func updateLearningButtonTitle() {
        // 检查该词库是否有学习记录
        let hasLearningRecords = LLLearningStore.shared.allRecords().contains { $0.listId == wordListId }
        
        if hasLearningRecords {
            startLearningButton.title = "继续学习"
        } else {
            startLearningButton.title = "开始学习"
        }
    }
    
    private func applyFilter() {
        let searchText = searchField.stringValue.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        if searchText.isEmpty {
            filteredWords = allWords
        } else {
            filteredWords = allWords.filter { word in
                word.word.lowercased().contains(searchText) ||
                word.translation.lowercased().contains(searchText)
            }
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Actions
    
    @objc private func didClickBack() {
        // 返回上一页
        dismiss(self)
    }
    
    @objc private func onSearchChanged() {
        applyFilter()
    }
    
    @objc private func didClickStartLearning() {
        LLLogger.info("🎯 开始学习词库：\(wordListName) (ID: \(wordListId))")
        
        // 1. 设置当前词库为默认词库
        LLSettingsStore.shared.currentListId = wordListId
        
        // 2. 发送通知刷新侧边栏数据
        NotificationCenter.default.post(name: .currentWordListChanged, object: nil)
        
        // 3. 关闭当前页面
        dismiss(self)
        
        LLLogger.info("✅ 已设置当前词库为：\(wordListName)")
    }
}

// MARK: - NSTableViewDataSource

extension LLWordListDetailViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredWords.count
    }
}

// MARK: - NSTableViewDelegate

extension LLWordListDetailViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < filteredWords.count else { return nil }
        
        let word = filteredWords[row]
        let identifier = NSUserInterfaceItemIdentifier("WordCell")
        
        // 创建或复用 cell
        var cellView = tableView.makeView(withIdentifier: identifier, owner: self) as? LLWordCellView
        
        if cellView == nil {
            cellView = LLWordCellView()
            cellView?.identifier = identifier
        }
        
        // 配置 cell
        cellView?.configure(with: word, row: row, delegate: self)
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false  // 禁用行选择，避免与按钮冲突
    }
}

// MARK: - Word Cell Delegate

extension LLWordListDetailViewController {
    
    @objc func didClickPlayUS(_ sender: NSButton) {
        let row = sender.tag
        guard row < filteredWords.count else { return }
        let word = filteredWords[row]
        
        LLLogger.debug("🔊 播放美式发音：\(word.word)")
        
        // 使用语音管理器播放美式发音
        LLPronunciationManager.shared.speak(word: word.word, accent: .us) { success, error in
            if let error = error {
                LLLogger.error("❌ 播放失败：\(error.localizedDescription)")
            } else if success {
                LLLogger.info("✅ 播放完成")
            }
        }
    }
    
    @objc func didClickPlayUK(_ sender: NSButton) {
        let row = sender.tag
        guard row < filteredWords.count else { return }
        let word = filteredWords[row]
        
        LLLogger.debug("🔊 播放英式发音：\(word.word)")
        
        // 使用语音管理器播放英式发音
        LLPronunciationManager.shared.speak(word: word.word, accent: .uk) { success, error in
            if let error = error {
                LLLogger.error("❌ 播放失败：\(error.localizedDescription)")
            } else if success {
                LLLogger.info("✅ 播放完成")
            }
        }
    }
}

