//
//  LLWordListTabViewController.swift
//  LearnLanguage
//
//  词库管理模块 - NSCollectionView 实现

import AppKit
import SnapKit
import UniformTypeIdentifiers

final class LLWordListTabViewController: NSViewController {
    
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
        return button
    }()
    
    // 类型筛选
    private lazy var typeFilterPopUp: NSPopUpButton = {
        let popUp = NSPopUpButton()
        popUp.target = self
        popUp.action = #selector(onFilterChanged)
        return popUp
    }()
    
    // 状态筛选
    private lazy var statusFilterPopUp: NSPopUpButton = {
        let popUp = NSPopUpButton()
        popUp.addItems(withTitles: [
            NSLocalizedString("All Status", comment: ""),
            NSLocalizedString("Not Started", comment: ""),
            NSLocalizedString("Learning", comment: ""),
            NSLocalizedString("Completed", comment: "")
        ])
        popUp.target = self
        popUp.action = #selector(onFilterChanged)
        return popUp
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
    
    // MARK: - Constants
    
    private let itemIdentifier = NSUserInterfaceItemIdentifier("LLWordLibraryCardItem")
    private let itemSpacing: CGFloat = 24
    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = NSEdgeInsets(top: 4, left: 0, bottom: 28, right: 4)
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 700, height: 450))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCollectionView()
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
        
        view.addSubview(controlsContainerView)
        controlsContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(32)
            make.right.equalToSuperview().offset(-32)
            make.top.equalTo(cardTitleLabel.snp.bottom).offset(28)
            make.height.equalTo(36)
        }
        
        controlsContainerView.addSubview(typeFilterPopUp)
        controlsContainerView.addSubview(statusFilterPopUp)
        controlsContainerView.addSubview(gridViewButton)
        controlsContainerView.addSubview(listViewButton)
        
        loadCategoriesForFilter()
        styleFilterPopUp(typeFilterPopUp)
        styleFilterPopUp(statusFilterPopUp)
        
        typeFilterPopUp.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(128)
        }
        
        statusFilterPopUp.snp.makeConstraints { make in
            make.left.equalTo(typeFilterPopUp.snp.right).offset(12)
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
        // 配置 FlowLayout
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = itemSpacing
        flowLayout.minimumLineSpacing = itemSpacing
        flowLayout.sectionInset = sectionInsets
        
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
        typeFilterPopUp.removeAllItems()
        typeFilterPopUp.addItem(withTitle: NSLocalizedString("All Types", comment: ""))
        
        do {
            let categories = try LLDatabaseManager.shared.getAllCategories()
            for category in categories {
                typeFilterPopUp.addItem(withTitle: category.name)
            }
        } catch {
            LLLogger.error("❌ 加载分类失败：\(error)")
            typeFilterPopUp.addItems(withTitles: ["官方词库", "自定义词库"])
        }
    }
    
    private func styleFilterPopUp(_ popUp: NSPopUpButton) {
        popUp.wantsLayer = true
        popUp.layer?.backgroundColor = LLAppearanceManager.shared.colors.surfaceContainerLow.cgColor
        popUp.layer?.cornerRadius = 18
        popUp.font = NSFont.inter(12, .semiBold)
        popUp.contentTintColor = LLAppearanceManager.shared.colors.secondaryText
    }
    
    private func refreshSummaryTexts() {
        cardTitleLabel.stringValue = String(format: NSLocalizedString("Word Libraries Summary", comment: "Word libraries summary"), filteredLists.count)
        heroSubtitleLabel.stringValue = String(format: NSLocalizedString("Word Libraries Summary", comment: "Word libraries summary"), filteredLists.count)
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
                if let categoryId = dbList.categoryId {
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
                    totalWords: totalWords
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
    
    private func applyFilters() {
        var result = allLists
        
        // 搜索
        let searchText = searchField.stringValue.lowercased()
        if !searchText.isEmpty {
            result = result.filter { $0.name.lowercased().contains(searchText) }
        }
        
        // 类型筛选
        let typeIndex = typeFilterPopUp.indexOfSelectedItem
        if typeIndex > 0 {
            let selectedCategory = typeFilterPopUp.titleOfSelectedItem ?? ""
            result = result.filter { $0.category == selectedCategory }
        }
        
        // 状态筛选
        let statusIndex = statusFilterPopUp.indexOfSelectedItem
        if statusIndex > 0 {
            result = result.filter { getListStatus($0) == statusIndex - 1 }
        }
        
        filteredLists = result
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
        
        let wordList = filteredLists[indexPath.item]
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
        
        let totalSpacing = sectionInsets.left + sectionInsets.right + (itemSpacing * (itemsPerRow - 1))
        let availableWidth = visibleWidth - totalSpacing - scrollerWidth
        
        // 使用更精确的计算，避免累积误差
        let itemWidth = (availableWidth / itemsPerRow).rounded(.down)
        
        return NSSize(width: itemWidth, height: 244)
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


