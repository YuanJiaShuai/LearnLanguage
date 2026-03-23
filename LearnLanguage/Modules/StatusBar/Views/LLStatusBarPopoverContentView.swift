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
        static let sectionSpacing: CGFloat = 8
        static let menuItemHeight: CGFloat = 32
        static let dividerHeight: CGFloat  = 1
        static let padding: CGFloat        = 8
    }

    // MARK: - Callbacks

    var onClose: (() -> Void)?

    // MARK: - UI

    private lazy var searchWordView: LLSearchWordView = {
        let v = LLSearchWordView(
            frame: NSRect(x: 0, y: 0, width: Layout.width, height: LLSearchWordView.viewHeight)
        )
        v.onHeightChanged = { [weak self] _ in
            self?.updatePanelHeight()
        }
        
        return v
    }()

    /// 搜索框标题
    private lazy var titleLabel: NSTextField = {
        let tf = NSTextField(labelWithString: NSLocalizedString("查词", comment: ""))
        tf.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        tf.textColor = .labelColor
        return tf
    }()

    private lazy var topDivider: NSBox = {
        let box = NSBox()
        box.boxType = .separator
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
        addSubview(titleLabel)
        addSubview(searchWordView)
        addSubview(topDivider)
        addSubview(menuStack)

        // 标题在顶部
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(20)
        }

        // 搜索框在标题下方，高度提高到 48
        searchWordView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }

        topDivider.snp.makeConstraints { make in
            make.top.equalTo(searchWordView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.dividerHeight)
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
        box.snp.makeConstraints { make in
            make.height.equalTo(Layout.dividerHeight)
            make.width.equalTo(Layout.width)
        }
        menuStack.addArrangedSubview(box)
    }

    // MARK: - Height

    /// 初始首选高度
    var preferredHeight: CGFloat {
        return 20  // 标题高度
            + 8    // 标题到搜索框间距
            + 48   // 搜索框高度
            + Layout.dividerHeight
            + CGFloat(menuStack.arrangedSubviews.count) * Layout.menuItemHeight
            + Layout.dividerHeight // 菜单内分割线
    }

    private func updatePanelHeight() {
        guard let panel = window as? LLStatusBarPopoverPanel else { return }
        // 重新计算总高度
        let titleH: CGFloat = 20
        let titleSpacing: CGFloat = 8
        let searchH: CGFloat = 48
        let dividerH = Layout.dividerHeight
        let menuH = menuStack.arrangedSubviews.reduce(CGFloat(0)) { $0 + $1.frame.height }
        let totalH = titleH + titleSpacing + searchH + dividerH + menuH

        var frame = panel.frame
        let delta = totalH - frame.height
        frame.origin.y -= delta
        frame.size.height = totalH
        panel.setFrame(frame, display: true, animate: false)
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
        iv.contentTintColor = .labelColor
        return iv
    }()

    private lazy var titleLabel: NSTextField = {
        let tf = NSTextField(labelWithString: "")
        tf.font = NSFont.systemFont(ofSize: 13)
        tf.textColor = .labelColor
        return tf
    }()

    init(title: String, iconName: String, action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = 6

        titleLabel.stringValue = title
        if let img = NSImage(systemSymbolName: iconName, accessibilityDescription: nil) {
            iconView.image = img
        }

        addSubview(iconView)
        addSubview(titleLabel)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-14)
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
        layer?.backgroundColor = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.15).cgColor
    }

    override func mouseExited(with event: NSEvent) {
        isHovered = false
        layer?.backgroundColor = .none
    }

    override func mouseDown(with event: NSEvent) {
        layer?.backgroundColor = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.25).cgColor
    }

    override func mouseUp(with event: NSEvent) {
        layer?.backgroundColor = isHovered
            ? NSColor.selectedContentBackgroundColor.withAlphaComponent(0.15).cgColor
            : .none
        let loc = convert(event.locationInWindow, from: nil)
        if bounds.contains(loc) {
            action()
        }
    }
}
