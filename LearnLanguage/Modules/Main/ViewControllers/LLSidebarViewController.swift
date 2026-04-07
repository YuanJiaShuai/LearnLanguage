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
        case .wordList: return NSLocalizedString("Word List", comment: "Word list module")
        case .learningRecord: return NSLocalizedString("Progress", comment: "Learning progress module")
        case .settings: return NSLocalizedString("Settings", comment: "Settings module")
        case .dataManagement: return NSLocalizedString("Data", comment: "Data management module")
        }
    }
    
    var icon: NSImage? {
        switch self {
        case .wordList: return NSImage(systemSymbolName: "books.vertical.fill", accessibilityDescription: nil)
        case .learningRecord: return NSImage(systemSymbolName: "chart.bar.xaxis", accessibilityDescription: nil)
        case .settings: return NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: nil)
        case .dataManagement: return NSImage(systemSymbolName: "externaldrive.fill", accessibilityDescription: nil)
        }
    }
}

final class LLSidebarViewController: NSViewController {
    
    // MARK: - Properties
    
    weak var delegate: SidebarViewControllerDelegate?
    private var selectedModule: SidebarModule = .wordList
    private let modules: [SidebarModule] = [.wordList, .settings, .learningRecord, .dataManagement]
    
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
        imageView.image = NSImage(systemSymbolName: "book.closed.fill", accessibilityDescription: nil)
        imageView.contentTintColor = .white
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = LLAppearanceManager.shared.colors.primaryContainer.cgColor
        imageView.layer?.cornerRadius = 12
        return imageView
    }()
    
    private lazy var logoLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("App Name", comment: "Application name"))
        label.font = NSFont.systemFont(ofSize: 20, weight: .bold)
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
    
    private lazy var currentWordLibIconView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = NSImage(systemSymbolName: "book.fill", accessibilityDescription: nil)
        imageView.contentTintColor = LLAppearanceManager.shared.colors.secondaryText
        return imageView
    }()
    
    private lazy var currentWordLibTitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "快速访问")
        label.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.5)
        return label
    }()
    
    private lazy var currentWordLibCardView: LLShortcutCardView = {
        let card = LLShortcutCardView(type: .wordList)
        card.onTap = { [weak self] in
            self?.didClickCurrentWordLib()
        }
        return card
    }()
    
    private lazy var wrongWordsIconView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = NSImage(systemSymbolName: "exclamationmark.circle.fill", accessibilityDescription: nil)
        imageView.contentTintColor = LLAppearanceManager.shared.colors.secondaryText
        return imageView
    }()
    
    private lazy var wrongWordsTitleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "主菜单")
        label.font = NSFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.5)
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
    
    private lazy var feedbackButton: NSButton = {
        let button = NSButton(title: "Curator\nHigh-End Curator", target: self, action: #selector(onFeedbackButtonClicked))
        button.bezelStyle = .regularSquare
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        button.contentTintColor = LLAppearanceManager.shared.colors.primaryText
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.42).cgColor
        button.layer?.cornerRadius = 14
        button.layer?.borderWidth = 1
        button.layer?.borderColor = NSColor.white.withAlphaComponent(0.5).cgColor
        button.alignment = .left
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 256, height: 400))
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
        setupBottomFeedbackButton()
        setupNavigationSection()
        topDivider.isHidden = true
        middleDivider.isHidden = true
        currentWordLibIconView.isHidden = true
        wrongWordsIconView.isHidden = true
    }
    
    private func setupLogoSection() {
        view.addSubview(logoContainerView)
        logoContainerView.addSubview(logoIconView)
        logoContainerView.addSubview(logoLabel)
        view.addSubview(topDivider)
        
        logoContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(22)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(64)
        }
        
        logoIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        logoLabel.snp.makeConstraints { make in
            make.leading.equalTo(logoIconView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(8)
        }
        
        topDivider.snp.makeConstraints { make in
            make.top.equalTo(logoContainerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    private func setupShortcutSection() {
        view.addSubview(shortcutContainerView)
        shortcutContainerView.addSubview(currentWordLibIconView)
        shortcutContainerView.addSubview(currentWordLibTitleLabel)
        shortcutContainerView.addSubview(currentWordLibCardView)
        shortcutContainerView.addSubview(wrongWordsIconView)
        shortcutContainerView.addSubview(wrongWordsTitleLabel)
        shortcutContainerView.addSubview(wrongWordsCardView)
        view.addSubview(middleDivider)
        
        shortcutContainerView.snp.makeConstraints { make in
            make.top.equalTo(logoContainerView.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(18)
        }
        
        currentWordLibIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(0)
        }
        
        currentWordLibTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.equalToSuperview()
            make.height.equalTo(16)
        }
        
        currentWordLibCardView.snp.makeConstraints { make in
            make.top.equalTo(currentWordLibTitleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
        }
        
        wrongWordsIconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(currentWordLibCardView.snp.bottom).offset(30)
            make.width.height.equalTo(0)
        }
        
        wrongWordsTitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.equalTo(currentWordLibCardView.snp.bottom).offset(30)
            make.height.equalTo(16)
        }
        
        wrongWordsCardView.snp.makeConstraints { make in
            make.top.equalTo(wrongWordsTitleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
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
            make.top.equalTo(middleDivider.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(feedbackButton.snp.top).offset(-20)
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
    
    private func setupBottomFeedbackButton() {
        view.addSubview(feedbackButton)
        feedbackButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(56)
        }
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
    
    @objc private func onFeedbackButtonClicked() {
        let email = "yjs_maoge@163.com"
        let alert = NSAlert()
        alert.messageText = "意见与建议反馈"
        alert.informativeText = "反馈邮箱：\(email)\n你可以先复制邮箱，或直接前往邮件客户端发送。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "复制")
        alert.addButton(withTitle: "发送")
        alert.addButton(withTitle: "取消")
        
        let result = alert.runModal()
        switch result {
        case .alertFirstButtonReturn:
            copyEmailToPasteboard(email)
        case .alertSecondButtonReturn:
            openMailClient(email)
        default:
            break
        }
    }
    
    private func copyEmailToPasteboard(_ email: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(email, forType: .string)
    }
    
    private func openMailClient(_ email: String) {
        guard let url = URL(string: "mailto:\(email)") else { return }
        NSWorkspace.shared.open(url)
    }
    
    @objc private func onCurrentWordListChanged() {
        loadCurrentWordList()
    }
    
    @objc private func onWrongWordsCountChanged() {
        loadWrongWordsCount()
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
            currentWordLibCardView.updateContent(title: NSLocalizedString("No Word List", comment: "No word list placeholder"), badge: "0/0")
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
            // 获取今日需要复习的词汇数量（所有词库）
            let reviewRecords = try LLDatabaseManager.shared.getTodayReviewWords()
            wrongWordCount = reviewRecords.count
        } catch {
            LLLogger.error("❌ 获取复习词汇数量失败：\(error)")
            wrongWordCount = 0
        }
        wrongWordsCardView.updateContent(title: NSLocalizedString("Today's Review", comment: "Today's review section title"), badge: "\(wrongWordCount)")
    }
}
