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
    
    // 顶部标题
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "词库管理")
        label.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.moduleTitleText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    // 新建词库按钮
    private lazy var newWordLibButton: NSButton = {
        let button = NSButton(title: "新建词库", target: self, action: #selector(didClickNewWordLib))
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)
        button.imagePosition = .imageLeading
        button.image?.isTemplate = true
        button.contentTintColor = .white
        button.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.systemBlue.cgColor
        button.layer?.cornerRadius = 8
        button.isBordered = false
        button.imageHugsTitle = true  // 让图标和文字靠近
        
        return button
    }()
    
    // 主内容容器（卡片背景）
    private lazy var contentContainerView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
        view.layer?.cornerRadius = 8
        view.layer?.borderWidth = 1
        view.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        return view
    }()
    
    // 卡片标题
    private lazy var cardTitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "词库管理（共 0 个）")
        label.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    // 搜索框
    private lazy var searchField: NSSearchField = {
        let field = NSSearchField()
        field.placeholderString = "搜索词库名称..."
        field.target = self
        field.action = #selector(onSearchChanged)
        return field
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
        popUp.addItems(withTitles: ["所有状态", "未开始", "学习中", "已完成"])
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
    private let itemSpacing: CGFloat = 12
    private let itemsPerRow: CGFloat = 3
    private let sectionInsets = NSEdgeInsets(top: 20, left: 0, bottom: 20, right: 20)
    
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
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.mainBackground.cgColor
        
        // 1. 添加顶部标题
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.top.equalToSuperview().offset(28)
        }
        
        // 2. 添加新建词库按钮
        view.addSubview(newWordLibButton)
        newWordLibButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-28)
            make.top.equalToSuperview().offset(28)
            make.height.equalTo(32)
        }
        
        // 3. 添加主内容容器
        view.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.right.equalToSuperview().offset(-28)
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.bottom.equalToSuperview().offset(-28)
        }
        
        // 4. 在容器内添加卡片标题
        contentContainerView.addSubview(cardTitleLabel)
        cardTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
        }
        
        // 5. 添加搜索框
        contentContainerView.addSubview(searchField)
        searchField.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(cardTitleLabel.snp.bottom).offset(16)
            make.width.equalTo(200)
            make.height.equalTo(28)
        }
        
        // 6. 添加类型筛选
        loadCategoriesForFilter()
        contentContainerView.addSubview(typeFilterPopUp)
        typeFilterPopUp.snp.makeConstraints { make in
            make.left.equalTo(searchField.snp.right).offset(12)
            make.centerY.equalTo(searchField)
            make.width.equalTo(120)
        }
        
        // 7. 添加状态筛选
        contentContainerView.addSubview(statusFilterPopUp)
        statusFilterPopUp.snp.makeConstraints { make in
            make.left.equalTo(typeFilterPopUp.snp.right).offset(12)
            make.centerY.equalTo(searchField)
            make.width.equalTo(120)
        }
        
        // 8. 添加 CollectionView 滚动容器
        contentContainerView.addSubview(collectionScrollView)
        collectionScrollView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(searchField.snp.bottom).offset(16)
            make.bottom.equalToSuperview().offset(-20)
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
        typeFilterPopUp.addItem(withTitle: "所有类型")
        
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
    
    private func loadAndFilterData() {
        // 从数据库加载词库数据
        do {
            let dbWordLists = try LLDatabaseManager.shared.getAllWordLists()
            LLLogger.debug("📊 从数据库加载了 \(dbWordLists.count) 个词库")
            
            // 转换为 WordList 模型
            allLists = dbWordLists.compactMap { dbList -> WordList? in
                guard let id = dbList.id else { return nil }
                
                var categoryName = "未分类"
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
        
        // 更新标题
        cardTitleLabel.stringValue = "词库管理（共 \(filteredLists.count) 个）"
        
        // 刷新 CollectionView
        collectionView.reloadData()
    }
    
    private func getListStatus(_ list: WordList) -> Int {
        let learned = LLLearningStore.shared.allRecords().filter { $0.listId == list.id }.count
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
        alert.messageText = "新建词库"
        alert.informativeText = "请输入词库名称："
        alert.addButton(withTitle: "创建")
        alert.addButton(withTitle: "取消")
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        input.placeholderString = "例如：我的单词本"
        alert.accessoryView = input
        alert.window.initialFirstResponder = input
        
        if alert.runModal() == .alertFirstButtonReturn {
            let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return }
            
            let newList = WordList(
                name: name,
                category: "自定义词库",
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
        
        return NSSize(width: itemWidth, height: 90)
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


