//
//  LLWordListTabViewController.swift
//  LearnLanguage
//
//  词库管理模块 - NSCollectionView 实现

import AppKit
import SnapKit
import UniformTypeIdentifiers

final class LLWordListTabViewController: NSViewController {
    
    private enum ViewMode {
        case grid
        case list
    }
    
    // MARK: - UI Components
    
    // 顶部小标题
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Word List Module Title", comment: ""))
        label.font = NSFont.inter(13, .semiBold)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.62)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    // 主标题
    private lazy var heroTitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("My Word Libraries", comment: "My word libraries title"))
        label.font = NSFont.inter(42, .bold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    // 副标题
    private lazy var heroSubtitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.inter(14, .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.6)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var vocabularyNotebookButtonShadowView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.shadowColor = NSColor.systemOrange.withAlphaComponent(0.18).cgColor
        view.layer?.shadowOpacity = 1
        view.layer?.shadowOffset = CGSize(width: 0, height: -4)
        view.layer?.shadowRadius = 12
        return view
    }()
    
    private lazy var vocabularyNotebookButton: NSButton = {
        let button = NSButton(title: "生词本", target: self, action: #selector(didClickVocabularyNotebook))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.image = NSImage(systemSymbolName: "text.badge.plus", accessibilityDescription: nil)
        button.imagePosition = .imageLeading
        button.image?.isTemplate = true
        button.contentTintColor = .white
        button.font = NSFont.inter(14, .semiBold)
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.systemOrange.cgColor
        button.layer?.cornerRadius = 12
        button.isBordered = false
        button.imageHugsTitle = true
        return button
    }()
    
    private lazy var newWordLibButtonShadowView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.shadowColor = LLAppearanceManager.shared.colors.accentColor.withAlphaComponent(0.22).cgColor
        view.layer?.shadowOpacity = 1
        view.layer?.shadowOffset = CGSize(width: 0, height: -4)
        view.layer?.shadowRadius = 12
        return view
    }()
    
    // 新建词库按钮
    private lazy var newWordLibButton: NSButton = {
        let button = NSButton(title: NSLocalizedString("New Word List", comment: ""), target: self, action: #selector(didClickNewWordLib))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)
        button.imagePosition = .imageLeading
        button.image?.isTemplate = true
        button.contentTintColor = .white
        button.font = NSFont.inter(14, .semiBold)
        button.wantsLayer = true
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        button.layer?.cornerRadius = 12
        button.isBordered = false
        button.imageHugsTitle = true  // 让图标和文字靠近
        
        return button
    }()
    
    // 控制条容器
    private lazy var controlsContainerView: NSView = {
        let view = NSView()
        return view
    }()
    
    // 主内容容器（卡片背景）
    private lazy var contentContainerView: NSView = {
        let view = NSView()
        return view
    }()
    
    // 卡片标题
    private lazy var cardTitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: String(format: NSLocalizedString("Word Libraries Summary", comment: "Word libraries summary"), 0))
        label.font = NSFont.inter(14, .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.6)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    // 搜索框
    private lazy var searchField: NSSearchField = {
        let field = NSSearchField()
        field.placeholderString = NSLocalizedString("Search My Word Libraries", comment: "Search my word libraries placeholder")
        field.target = self
        field.action = #selector(onSearchChanged)
        field.focusRingType = .none
        field.bezelStyle = .roundedBezel
        return field
    }()
    
    private lazy var gridViewButton: NSButton = {
        let button = NSButton()
        button.isBordered = false
        button.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil)
        button.imagePosition = .imageOnly
        button.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        button.wantsLayer = true
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentLightBackground.cgColor
        button.layer?.cornerRadius = 10
        button.target = self
        button.action = #selector(switchToGridView)
        return button
    }()
    
    private lazy var listViewButton: NSButton = {
        let button = NSButton()
        button.isBordered = false
        button.image = NSImage(systemSymbolName: "list.bullet", accessibilityDescription: nil)
        button.imagePosition = .imageOnly
        button.contentTintColor = LLAppearanceManager.shared.colors.secondaryText
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.clear.cgColor
        button.layer?.cornerRadius = 10
        button.target = self
        button.action = #selector(switchToListView)
        return button
    }()
    
    // 类型筛选
    private lazy var typeFilterChipView: LLFilterChipView = {
        let chip = LLFilterChipView()
        chip.onSelectionChanged = { [weak self] _, _ in
            self?.applyFilters()
        }
        return chip
    }()
    
    // 状态筛选
    private lazy var statusFilterChipView: LLFilterChipView = {
        let chip = LLFilterChipView()
        chip.onSelectionChanged = { [weak self] _, _ in
            self?.applyFilters()
        }
        return chip
    }()
    
    // CollectionView 滚动容器
    private lazy var collectionScrollView: NSScrollView = {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.documentView = collectionView
        return scrollView
    }()
    
    // CollectionView
    private lazy var collectionView: NSCollectionView = {
        let collectionView = NSCollectionView()
        collectionView.backgroundColors = [.clear]
        return collectionView
    }()
    
    // MARK: - Data
    
    private var allLists: [WordList] = []
    private var filteredLists: [WordList] = []
    private var selectedListId: String?
    private var viewMode: ViewMode = .grid
    
    // MARK: - Constants
    
    private let itemIdentifier = NSUserInterfaceItemIdentifier("LLWordLibraryCardItem")
    private let itemSpacing: CGFloat = 24
    private let gridItemsPerRow: CGFloat = 3
    private let gridSectionInsets = NSEdgeInsets(top: 4, left: 0, bottom: 28, right: 4)
    private let listSectionInsets = NSEdgeInsets(top: 4, left: 0, bottom: 28, right: 4)
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 450))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
        updateViewModeUI()
        loadAndFilterData()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDataChanged),
            name: .learnLanguageReloadWordLists,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onCurrentWordListChanged),
            name: .currentWordListChanged,
            object: nil
        )
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.top.equalToSuperview().offset(24)
        }
        
        view.addSubview(heroTitleLabel)
        heroTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
        }
        
        view.addSubview(cardTitleLabel)
        cardTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.top.equalTo(heroTitleLabel.snp.bottom).offset(8)
        }
        
        view.addSubview(newWordLibButtonShadowView)
        newWordLibButtonShadowView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-32)
            make.centerY.equalTo(heroTitleLabel.snp.centerY).offset(4)
            make.height.equalTo(40)
        }
        
        newWordLibButtonShadowView.addSubview(newWordLibButton)
        newWordLibButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(vocabularyNotebookButtonShadowView)
        vocabularyNotebookButtonShadowView.snp.makeConstraints { make in
            make.right.equalTo(newWordLibButtonShadowView.snp.left).offset(-12)
            make.centerY.equalTo(heroTitleLabel.snp.centerY).offset(4)
            make.height.equalTo(40)
        }
        
        vocabularyNotebookButtonShadowView.addSubview(vocabularyNotebookButton)
        vocabularyNotebookButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(controlsContainerView)
        controlsContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.top.equalTo(cardTitleLabel.snp.bottom).offset(28)
            make.height.equalTo(36)
        }
        
        controlsContainerView.addSubview(typeFilterChipView)
        controlsContainerView.addSubview(statusFilterChipView)
        controlsContainerView.addSubview(gridViewButton)
        controlsContainerView.addSubview(listViewButton)
        
        loadCategoriesForFilter()
        configureStatusFilterChip()
        
        typeFilterChipView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(128)
        }
        
        statusFilterChipView.snp.makeConstraints { make in
            make.left.equalTo(typeFilterChipView.snp.right).offset(12)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(128)
        }
        
        listViewButton.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview()
            make.width.equalTo(36)
        }
        
        gridViewButton.snp.makeConstraints { make in
            make.right.equalTo(listViewButton.snp.left).offset(-8)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(36)
        }
        
        view.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.top.equalTo(controlsContainerView.snp.bottom).offset(28)
            make.bottom.equalToSuperview().offset(-32)
        }
        
        contentContainerView.addSubview(collectionScrollView)
        collectionScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    
    private func setupCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = itemSpacing
        flowLayout.minimumLineSpacing = itemSpacing
        flowLayout.sectionInset = gridSectionInsets
        
        collectionView.collectionViewLayout = flowLayout
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isSelectable = false  // 改为不可选中，使用点击事件
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColors = [.clear]
        
        // 注册 Item
        collectionView.register(
            LLWordLibraryCardItem.self,
            forItemWithIdentifier: itemIdentifier
        )
    }
    
    // MARK: - Data Loading
    
    private func loadCategoriesForFilter() {
        var items: [LLFilterChipView.Item] = [
            .init(title: NSLocalizedString("Word Library Type", comment: "Word library type filter"), representedValue: "")
        ]
        
        do {
            let categories = try LLDatabaseManager.shared.getAllCategories()
            items.append(contentsOf: categories.map { .init(title: $0.name, representedValue: $0.name) })
        } catch {
            LLLogger.error("❌ 加载分类失败：\(error)")
            items.append(contentsOf: [
                .init(title: "官方词库", representedValue: "官方词库"),
                .init(title: "自定义词库", representedValue: "自定义词库")
            ])
        }
        
        typeFilterChipView.configure(items: items)
    }
    
    private func configureStatusFilterChip() {
        let items: [LLFilterChipView.Item] = [
            .init(title: NSLocalizedString("Learning Status", comment: "Learning status filter"), representedValue: ""),
            .init(title: NSLocalizedString("Not Started", comment: ""), representedValue: "0"),
            .init(title: NSLocalizedString("Learning", comment: ""), representedValue: "1"),
            .init(title: NSLocalizedString("Completed", comment: ""), representedValue: "2")
        ]
        statusFilterChipView.configure(items: items)
    }
    
    private func refreshSummaryTexts() {
        cardTitleLabel.stringValue = String(format: NSLocalizedString("Word Libraries Summary", comment: "Word libraries summary"), filteredLists.count)
        heroSubtitleLabel.stringValue = String(format: NSLocalizedString("Word Libraries Summary", comment: "Word libraries summary"), filteredLists.count)
    }
    
    private var currentItemsPerRow: CGFloat {
        viewMode == .grid ? gridItemsPerRow : 1
    }
    
    private var currentSectionInsets: NSEdgeInsets {
        viewMode == .grid ? gridSectionInsets : listSectionInsets
    }
    
    private func updateViewModeUI() {
        let isGrid = viewMode == .grid
        gridViewButton.contentTintColor = isGrid ? LLAppearanceManager.shared.colors.accentColor : LLAppearanceManager.shared.colors.secondaryText
        gridViewButton.layer?.backgroundColor = isGrid ? LLAppearanceManager.shared.colors.accentLightBackground.cgColor : NSColor.clear.cgColor
        listViewButton.contentTintColor = isGrid ? LLAppearanceManager.shared.colors.secondaryText : LLAppearanceManager.shared.colors.accentColor
        listViewButton.layer?.backgroundColor = isGrid ? NSColor.clear.cgColor : LLAppearanceManager.shared.colors.accentLightBackground.cgColor
        
        if let flowLayout = collectionView.collectionViewLayout as? NSCollectionViewFlowLayout {
            flowLayout.sectionInset = currentSectionInsets
            flowLayout.invalidateLayout()
        }
        collectionView.reloadData()
    }
    
    private func badgeTitle(for list: WordList) -> String? {
        return nil
    }
    
    private func loadAndFilterData() {
        // 从数据库加载词库数据
        do {
            let dbWordLists = try LLDatabaseManager.shared.getAllWordLists()
            LLLogger.debug("📊 从数据库加载了 \(dbWordLists.count) 个词库")
            
            // 转换为 WordList 模型
            allLists = dbWordLists.compactMap { dbList -> WordList? in
                guard let id = dbList.id else { return nil }
                
                var categoryName = NSLocalizedString("Uncategorized", comment: "")
                if dbList.description == LLWordListStorage.vocabularyNotebookDescription {
                    categoryName = "内置"
                } else if let categoryId = dbList.categoryId {
                    if let category = try? LLDatabaseManager.shared.getCategoryById(categoryId) {
                        categoryName = category.name
                    }
                }
                
                let totalWords = dbList.totalWords
                
                return WordList(
                    id: String(id),
                    name: dbList.name,
                    category: categoryName,
                    language: .english,
                    entries: [],
                    totalWords: totalWords,
                    isVocabularyNotebook: dbList.description == LLWordListStorage.vocabularyNotebookDescription
                )
            }
            
            LLLogger.debug("✅ 转换后得到 \(allLists.count) 个词库")
            
        } catch {
            LLLogger.error("❌ 从数据库加载词库失败：\(error)")
            allLists = LLWordListStorage.shared.allLists()
        }
        
        // 应用筛选
        applyFilters()
    }
    
    private func orderedLists(_ lists: [WordList]) -> [WordList] {
        lists.sorted {
            if $0.isVocabularyNotebook != $1.isVocabularyNotebook {
                return $0.isVocabularyNotebook && !$1.isVocabularyNotebook
            }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }
    
    private func applyFilters() {
        var result = allLists
        
        // 搜索
        let searchText = searchField.stringValue.lowercased()
        if !searchText.isEmpty {
            result = result.filter { $0.name.lowercased().contains(searchText) }
        }
        
        // 类型筛选
        let typeIndex = typeFilterChipView.selectedIndex
        if typeIndex > 0 {
            let selectedCategory = typeFilterChipView.items[typeIndex].representedValue
            result = result.filter { $0.category == selectedCategory }
        }
        
        // 状态筛选
        let statusIndex = statusFilterChipView.selectedIndex
        if statusIndex > 0 {
            let selectedStatus = Int(statusFilterChipView.items[statusIndex].representedValue) ?? 0
            result = result.filter { getListStatus($0) == selectedStatus }
        }
        
        filteredLists = orderedLists(result)
        LLLogger.debug("🔍 筛选后得到 \(filteredLists.count) 个词库")
        refreshSummaryTexts()
        collectionView.reloadData()
    }
    
    private func getListStatus(_ list: WordList) -> Int {
        let learned: Int
        do {
            let stats = try LLDatabaseManager.shared.getWordListProgressStats(wordListId: list.id)
            learned = stats.learned
        } catch {
            learned = 0
        }
        if learned == 0 {
            return 0 // 未开始
        } else if learned >= list.entryCount {
            return 2 // 已完成
        } else {
            return 1 // 学习中
        }
    }
    
    // MARK: - Actions
    
    @objc private func switchToGridView() {
        guard viewMode != .grid else { return }
        viewMode = .grid
        updateViewModeUI()
    }
    
    @objc private func switchToListView() {
        guard viewMode != .list else { return }
        viewMode = .list
        updateViewModeUI()
    }
    
    @objc private func didClickVocabularyNotebook() {
        guard let notebook = LLWordListStorage.shared.vocabularyNotebook(language: LLSettingsStore.shared.currentLanguage) else { return }
        showWordListDetail(wordList: notebook)
    }
    
    @objc private func didClickNewWordLib() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Create New Word List", comment: "")
        alert.informativeText = NSLocalizedString("Enter List Name", comment: "")
        alert.addButton(withTitle: NSLocalizedString("Create", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.placeholderString = NSLocalizedString("New List Name Placeholder", comment: "")
        alert.accessoryView = input
        alert.window.initialFirstResponder = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            
            let newList = WordList(
                name: name,
                category: NSLocalizedString("Custom Word List", comment: ""),
                language: LLSettingsStore.shared.currentLanguage,
                entries: []
            )
            
            LLWordListStorage.shared.addList(newList)
            loadAndFilterData()
            NotificationCenter.default.post(name: .learnLanguageReloadWordLists, object: nil)
        }
    }
    
    @objc private func onSearchChanged() {
        applyFilters()
    }
    
    @objc private func onFilterChanged() {
        applyFilters()
    }
    
    @objc private func onDataChanged() {
        loadAndFilterData()
    }
    
    @objc private func onCurrentWordListChanged() {
        // 当前词库变化时，只需要刷新 CollectionView 来更新徽章显示
        collectionView.reloadData()
    }
}

// MARK: - NSCollectionViewDataSource

extension LLWordListTabViewController: NSCollectionViewDataSource {
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return filteredLists.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(
            withIdentifier: itemIdentifier,
            for: indexPath
        ) as! LLWordLibraryCardItem
        
        item.layoutMode = (viewMode == .grid) ? .grid : .list
        let wordList = filteredLists[indexPath.item]
        item.badgeTitle = badgeTitle(for: wordList)
        item.configure(with: wordList) { [weak self] selectedList in
            // 点击卡片后跳转到详情页
            self?.showWordListDetail(wordList: selectedList)
        }
        
        return item
    }
}

// MARK: - NSCollectionViewDelegateFlowLayout

extension LLWordListTabViewController: NSCollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        // 使用 scrollView 的 contentSize 或者 documentVisibleRect 来获取更准确的宽度
        let scrollView = collectionView.enclosingScrollView
        let visibleWidth = scrollView?.documentVisibleRect.width ?? collectionView.bounds.width
        
        // 计算可用宽度时，要考虑滚动条的宽度
        let scrollerWidth: CGFloat = scrollView?.verticalScroller?.isHidden == false ? NSScroller.scrollerWidth(for: .regular, scrollerStyle: .overlay) : 0
        
        let totalSpacing = currentSectionInsets.left + currentSectionInsets.right + (itemSpacing * (currentItemsPerRow - 1))
        let availableWidth = visibleWidth - totalSpacing - scrollerWidth
        
        // 使用更精确的计算，避免累积误差
        let itemWidth = (availableWidth / currentItemsPerRow).rounded(.down)
        let itemHeight: CGFloat = viewMode == .grid ? 244 : 156
        
        return NSSize(width: itemWidth, height: itemHeight)
    }
}

// MARK: - Navigation

extension LLWordListTabViewController {
    
    /// 显示词库详情页
    private func showWordListDetail(wordList: WordList) {
        LLLogger.info("🔍 打开词库详情：\(wordList.name)")
        
        // 创建详情页
        let detailVC = LLWordListDetailViewController(
            wordListId: wordList.id,
            wordListName: wordList.name
        )
        
        // 以模态窗口形式展示
        presentAsSheet(detailVC)
    }
}


