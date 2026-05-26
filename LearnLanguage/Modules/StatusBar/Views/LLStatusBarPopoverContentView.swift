//
//  LLStatusBarPopoverContentView.swift
//  LearnLanguage
//
//  状态栏 Popover Panel 的内容视图
//  包含：查词区域 + 功能菜单项
//

import AppKit
import SnapKit

final class LLStatusBarPopoverContentView: NSView {

    // MARK: - Constants

    private enum Layout {
        static let width: CGFloat        = 300
        static let menuItemHeight: CGFloat = 40
        static let dividerHeight: CGFloat  = 1
        static let completionSectionHeight: CGFloat = 38
        static let cornerRadius: CGFloat = 18
    }
    
    private var shouldShowLearnAnotherBatchAction: Bool {
        if let listId = LLSettingsStore.shared.currentListId {
            LLDailyLearningManager.shared.setup(listId: listId)
        }
        return !LLDailyLearningManager.shared.hasPendingTasks
    }

    // MARK: - Callbacks

    var onClose: (() -> Void)?

    // MARK: - UI

    private lazy var searchWordView: LLSearchWordView = {
        let v = LLSearchWordView(
            frame: NSRect(x: 0, y: 0, width: Layout.width, height: LLSearchWordView.viewHeight)
        )
        v.onHeightChanged = { [weak self] newHeight in
            guard let self else { return }
            self.searchWordView.snp.updateConstraints { make in
                make.height.equalTo(newHeight)
            }
            self.updatePanelHeight(searchHeight: newHeight)
        }
        
        return v
    }()

    /// 搜索框标题
    private lazy var titleLabel: NSTextField = {
        let tf = NSTextField(labelWithString: NSLocalizedString("查询", comment: ""))
        tf.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        tf.textColor = NSColor.labelColor.withAlphaComponent(0.92)
        return tf
    }()

    private lazy var visualEffectView: NSVisualEffectView = {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = Layout.cornerRadius
        view.layer?.masksToBounds = true
        return view
    }()

    private lazy var tintOverlayView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.06).cgColor
        return view
    }()

    private lazy var topDivider: NSBox = {
        let box = NSBox()
        box.boxType = .separator
        box.alphaValue = 0.24
        return box
    }()

    private lazy var menuStack: NSStackView = {
        let sv = NSStackView()
        sv.orientation = .vertical
        sv.spacing = 0
        sv.alignment = .leading
        sv.distribution = .fill
        return sv
    }()
    
    private lazy var completionActionContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.white.withAlphaComponent(0.10).cgColor
        view.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.16).cgColor
        return view
    }()
    
    private lazy var learnAnotherBatchButton: NSButton = {
        let button = NSButton(title: NSLocalizedString("再学一组", comment: ""), target: self, action: #selector(onLearnAnotherBatch))
        button.isBordered = false
        button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        button.contentTintColor = NSColor.labelColor.withAlphaComponent(0.92)
        return button
    }()

    // MARK: - Init

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        wantsLayer = true
        layer?.cornerRadius = Layout.cornerRadius
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
        layer?.shadowColor = NSColor.black.withAlphaComponent(0.16).cgColor
        layer?.shadowOpacity = 1
        layer?.shadowRadius = 18
        layer?.shadowOffset = CGSize(width: 0, height: -2)

        addSubview(visualEffectView)
        addSubview(tintOverlayView)
        addSubview(titleLabel)
        addSubview(searchWordView)
        addSubview(topDivider)
        addSubview(menuStack)

        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tintOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 标题在顶部
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.top.equalTo(18)
        }

        // 搜索框在标题下方
        searchWordView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        
        if shouldShowLearnAnotherBatchAction {
            addSubview(completionActionContainer)
            completionActionContainer.addSubview(learnAnotherBatchButton)
            
            completionActionContainer.snp.makeConstraints { make in
                make.top.equalTo(searchWordView.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview().inset(18)
                make.height.equalTo(Layout.completionSectionHeight)
            }
            
            learnAnotherBatchButton.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            topDivider.snp.makeConstraints { make in
                make.top.equalTo(completionActionContainer.snp.bottom).offset(8)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(Layout.dividerHeight)
            }
        } else {
            topDivider.snp.makeConstraints { make in
                make.top.equalTo(searchWordView.snp.bottom).offset(10)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(Layout.dividerHeight)
            }
        }

        menuStack.snp.makeConstraints { make in
            make.top.equalTo(topDivider.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        buildMenuItems()
    }

    private func buildMenuItems() {
        // 打开主界面
        addMenuItem(
            title: NSLocalizedString("打开主界面", comment: ""),
            icon: "macwindow"
        ) { [weak self] in
            self?.onClose?()
            if let delegate = NSApp.delegate as? LLAppDelegate {
                delegate.showMainWindow()
            }
        }

        // 进入/退出打字模式
        let isTyping = LLStatusBarTypingPractice.shared.isVisible
        addMenuItem(
            title: isTyping ? NSLocalizedString("退出打字模式", comment: "") : NSLocalizedString("进入打字模式", comment: ""),
            icon: isTyping ? "keyboard.chevron.compact.down" : "keyboard"
        ) { [weak self] in
            self?.onClose?()
            LLStatusBarTypingPractice.shared.toggleVisibility()
        }

        // 分割线
        addDivider()

        // 退出
        addMenuItem(
            title: NSLocalizedString("退出", comment: ""),
            icon: "power"
        ) {
            NSApp.terminate(nil)
        }
    }

    // MARK: - Menu Item Builder

    private func addMenuItem(title: String, icon: String, action: @escaping () -> Void) {
        let item = LLPopoverMenuItem(title: title, iconName: icon, action: action)
        item.snp.makeConstraints { make in
            make.height.equalTo(Layout.menuItemHeight)
            make.width.equalTo(Layout.width)
        }
        menuStack.addArrangedSubview(item)
    }

    private func addDivider() {
        let box = NSBox()
        box.boxType = .separator
        box.alphaValue = 0.24
        box.snp.makeConstraints { make in
            make.height.equalTo(Layout.dividerHeight)
            make.width.equalTo(Layout.width)
        }
        menuStack.addArrangedSubview(box)
    }

    // MARK: - Height

    /// 初始首选高度
    var preferredHeight: CGFloat {
        let completionSection: CGFloat = shouldShowLearnAnotherBatchAction ? (6 + Layout.completionSectionHeight + 6) : 0
        return 20  // 标题高度
            + 8    // 标题到搜索框间距
            + 48   // 搜索框高度
            + completionSection
            + Layout.dividerHeight
            + CGFloat(menuStack.arrangedSubviews.count) * Layout.menuItemHeight
            + Layout.dividerHeight // 菜单内分割线
    }

    private func updatePanelHeight(searchHeight: CGFloat = 48) {
        guard let panel = window as? LLStatusBarPopoverPanel else { return }
        // 重新计算总高度
        let titleH: CGFloat = 20
        let titleSpacing: CGFloat = 8
        let completionSection: CGFloat = shouldShowLearnAnotherBatchAction ? (6 + Layout.completionSectionHeight + 6) : 0
        let dividerH = Layout.dividerHeight
        let menuH = menuStack.arrangedSubviews.reduce(CGFloat(0)) { $0 + $1.frame.height }
        let totalH = titleH + titleSpacing + searchHeight + completionSection + dividerH + menuH

        var frame = panel.frame
        let delta = totalH - frame.height
        frame.origin.y -= delta
        frame.size.height = totalH
        panel.setFrame(frame, display: true, animate: false)
    }

    // MARK: - Actions
    
    @objc private func onLearnAnotherBatch() {
        LLDailyLearningManager.shared.learnAnotherBatch()
        LLStatusBarManager.shared.refreshStatusBar()
        LLStatusBarTypingPractice.shared.syncWithStatusBarCurrentWord()
        onClose?()
    }

    // MARK: - Public

    func resetSearch() {
        searchWordView.reset()
    }

    func focusSearch() {
        searchWordView.focusSearchField()
    }
}

// MARK: - LLPopoverMenuItem

/// 单个菜单项视图
private final class LLPopoverMenuItem: NSView {

    private let action: () -> Void
    private var trackingArea: NSTrackingArea?
    private var isHovered = false

    private lazy var iconView: NSImageView = {
        let iv = NSImageView()
        iv.contentTintColor = NSColor.labelColor.withAlphaComponent(0.76)
        return iv
    }()

    private lazy var titleLabel: NSTextField = {
        let tf = NSTextField(labelWithString: "")
        tf.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        tf.textColor = NSColor.labelColor.withAlphaComponent(0.9)
        return tf
    }()

    init(title: String, iconName: String, action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 10

        titleLabel.stringValue = title
        if let img = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            iconView.image = img
        }

        addSubview(iconView)
        addSubview(titleLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(15)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-18)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = trackingArea { removeTrackingArea(ta) }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        isHovered = true
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.20).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.09).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        layer?.backgroundColor = .none
        layer?.borderWidth = 0
        layer?.borderColor = .none
    }

    override func mouseDown(with event: NSEvent) {
        layer?.backgroundColor = NSColor.white.withAlphaComponent(0.28).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.12).cgColor
    }

    override func mouseUp(with event: NSEvent) {
        layer?.backgroundColor = isHovered
            ? NSColor.white.withAlphaComponent(0.20).cgColor
            : .none
        layer?.borderWidth = isHovered ? 1 : 0
        layer?.borderColor = isHovered
            ? NSColor.white.withAlphaComponent(0.16).cgColor
            : .none
        let loc = convert(event.locationInWindow, from: nil)
        if bounds.contains(loc) {
            action()
        }
    }
}
