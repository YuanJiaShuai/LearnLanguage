//
//  LLSidebarViewController.swift
//  LearnLanguage
//
//  Finder 风格左侧导航栏
//

import AppKit
import SnapKit

protocol SidebarViewControllerDelegate: AnyObject {
    func sidebarViewController(_ vc: LLSidebarViewController, didSelectModule module: SidebarModule)
    func sidebarViewController(_ vc: LLSidebarViewController, didSelectCurrentWordList: WordList?)
    func sidebarViewController(_ vc: LLSidebarViewController, didSelectWrongWords: ())
}

enum SidebarModule {
    case wordList           // 词库管理
    case learningRecord     // 学习记录
    case settings          // 设置
    case dataManagement    // 数据管理
    
    var title: String {
        switch self {
        case .wordList: return "词库管理"
        case .learningRecord: return "学习记录"
        case .settings: return "学习设置"
        case .dataManagement: return "数据管理"
        }
    }
    
    var icon: NSImage? {
        switch self {
        case .wordList: return NSImage(systemSymbolName: "book.fill", accessibilityDescription: nil)
        case .learningRecord: return NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: nil)
        case .settings: return NSImage(systemSymbolName: "gearshape.fill", accessibilityDescription: nil)
        case .dataManagement: return NSImage(systemSymbolName: "externaldrive.fill", accessibilityDescription: nil)
        }
    }
}

final class LLSidebarViewController: NSViewController {
    
    // MARK: - Properties
    
    weak var delegate: SidebarViewControllerDelegate?
    private var selectedModule: SidebarModule = .wordList
    private let modules: [SidebarModule] = [.wordList, .learningRecord, .settings, .dataManagement]
    
    // 数据源
    private var currentWordList: WordList?
    private var wrongWordCount: Int = 0
    
    // 导航项视图
    private var navigationItemViews: [LLSidebarNavigationItemView] = []
    
    // MARK: - UI Components
    
    private lazy var logoContainerView: NSView = {
        let view = NSView()
        return view
    }()
    
    private lazy var logoIconView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: nil)
        imageView.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        return imageView
    }()
    
    private lazy var logoLabel: NSTextField = {
        let label = NSTextField(labelWithString: "摸鱼记词")
        label.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.accentColor
        return label
    }()
    
    private lazy var topDivider: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        return view
    }()
    
    private lazy var shortcutContainerView: NSView = {
        let view = NSView()
        return view
    }()
    
    private lazy var currentWordLibTitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "当前学习的词库")
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        return label
    }()
    
    private lazy var currentWordLibCardView: LLShortcutCardView = {
        let card = LLShortcutCardView(type: .wordList)
        card.onTap = { [weak self] in
            self?.didClickCurrentWordLib()
        }
        return card
    }()
    
    private lazy var wrongWordsTitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "当天需复习")
        label.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        return label
    }()
    
    private lazy var wrongWordsCardView: LLShortcutCardView = {
        let card = LLShortcutCardView(type: .wrongWords)
        card.onTap = { [weak self] in
            self?.didClickWrongWords()
        }
        return card
    }()
    
    private lazy var middleDivider: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        return view
    }()
    
    private lazy var navigationContainerView: NSView = {
        let view = NSView()
        return view
    }()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 180, height: 400))
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNotifications()
        loadData()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        setupLogoSection()
        setupShortcutSection()
        setupNavigationSection()
    }
    
    private func setupLogoSection() {
        view.addSubview(logoContainerView)
        logoContainerView.addSubview(logoIconView)
        logoContainerView.addSubview(logoLabel)
        view.addSubview(topDivider)
        
        logoContainerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(52)
        }
        
        logoIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }
        
        logoLabel.snp.makeConstraints { make in
            make.leading.equalTo(logoIconView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        
        topDivider.snp.makeConstraints { make in
            make.top.equalTo(logoContainerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    private func setupShortcutSection() {
        view.addSubview(shortcutContainerView)
        shortcutContainerView.addSubview(currentWordLibTitleLabel)
        shortcutContainerView.addSubview(currentWordLibCardView)
        shortcutContainerView.addSubview(wrongWordsTitleLabel)
        shortcutContainerView.addSubview(wrongWordsCardView)
        view.addSubview(middleDivider)
        
        shortcutContainerView.snp.makeConstraints { make in
            make.top.equalTo(topDivider.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        
        currentWordLibTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(16)
        }
        
        currentWordLibCardView.snp.makeConstraints { make in
            make.top.equalTo(currentWordLibTitleLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        wrongWordsTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(currentWordLibCardView.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(16)
        }
        
        wrongWordsCardView.snp.makeConstraints { make in
            make.top.equalTo(wrongWordsTitleLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-6)
        }
        
        middleDivider.snp.makeConstraints { make in
            make.top.equalTo(shortcutContainerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    private func setupNavigationSection() {
        view.addSubview(navigationContainerView)
        
        navigationContainerView.snp.makeConstraints { make in
            make.top.equalTo(middleDivider.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        
        var previousView: NSView?
        
        for (index, module) in modules.enumerated() {
            let navItemView = LLSidebarNavigationItemView(module: module)
            navItemView.onTap = { [weak self] in
                self?.didSelectNavigation(at: index)
            }
            navigationItemViews.append(navItemView)
            navigationContainerView.addSubview(navItemView)
            
            navItemView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview()
                
                if let previous = previousView {
                    make.top.equalTo(previous.snp.bottom)
                } else {
                    make.top.equalToSuperview()
                }
            }
            
            previousView = navItemView
        }
        
        updateNavigationSelection()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onCurrentWordListChanged),
            name: .currentWordListChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onWrongWordsCountChanged),
            name: .wrongWordsCountChanged,
            object: nil
        )
    }
    
    // MARK: - Actions
    
    private func didSelectNavigation(at index: Int) {
        let module = modules[index]
        selectedModule = module
        updateNavigationSelection()
        delegate?.sidebarViewController(self, didSelectModule: module)
    }
    
    private func updateNavigationSelection() {
        for (index, navItemView) in navigationItemViews.enumerated() {
            navItemView.isSelected = (modules[index] == selectedModule)
        }
    }
    
    private func didClickCurrentWordLib() {
        // 判断是否有当前词库
        if currentWordList == nil {
            // 没有词库：切换到词库管理 tab，显示词库管理页面
            selectedModule = .wordList
            updateNavigationSelection()
            delegate?.sidebarViewController(self, didSelectModule: .wordList)
        } else {
            // 有词库：直接显示词库详情
            delegate?.sidebarViewController(self, didSelectCurrentWordList: currentWordList)
        }
    }
    
    private func didClickWrongWords() {
        // 切换到学习记录 tab
        selectedModule = .learningRecord
        updateNavigationSelection()
        delegate?.sidebarViewController(self, didSelectModule: .learningRecord)
        delegate?.sidebarViewController(self, didSelectWrongWords: ())
    }
    
    @objc private func onCurrentWordListChanged() {
        loadData()
    }
    
    @objc private func onWrongWordsCountChanged() {
        loadData()
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        loadCurrentWordList()
        loadWrongWordsCount()
    }
    
    private func loadCurrentWordList() {
        guard let currentId = LLSettingsStore.shared.currentListId,
              let list = LLWordListStorage.shared.list(byId: currentId) else {
            // 没有词库时显示空状态
            currentWordList = nil
            currentWordLibCardView.updateContent(title: "暂无词库", badge: "0/0")
            return
        }
        
        currentWordList = list
        let learned: Int
        do {
            let stats = try LLDatabaseManager.shared.getWordListProgressStats(wordListId: currentId)
            learned = stats.learned
        } catch {
            LLLogger.error("❌ 获取学习进度失败：\(error)")
            learned = 0
        }
        let badgeText = "\(learned)/\(list.entries.count)"
        
        currentWordLibCardView.updateContent(title: list.name, badge: badgeText)
    }
    
    private func loadWrongWordsCount() {
        do {
            wrongWordCount = try LLDatabaseManager.shared.getWrongRecordCount(onlyUnreviewed: true)
        } catch {
            LLLogger.error("❌ 获取错题数量失败：\(error)")
            wrongWordCount = 0
        }
        wrongWordsCardView.updateContent(title: "未复习错题", badge: "\(wrongWordCount)")
    }
}
