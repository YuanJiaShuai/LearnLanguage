//
//  LLTodayRecordCardView.swift
//  LearnLanguage
//
//  今日学习记录卡片视图

import AppKit

final class LLTodayRecordCardView: NSView {
    
    // MARK: - UI Components
    
    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Today's Learning", comment: ""))
        label.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var exportButton: NSButton = {
        let button = NSButton(title: NSLocalizedString("Export Stats", comment: ""), target: self, action: #selector(exportButtonClicked))
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
    
    private let listContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        view.layer?.cornerRadius = 6
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.91, alpha: 1).cgColor
        return view
    }()
    
    private let scrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        return scroll
    }()
    
    private let listView = _FlippedView()
    
    // MARK: - Callbacks
    
    var onExportButtonClicked: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(srgbRed: 0.98, green: 0.98, blue: 0.97, alpha: 1).cgColor
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.91, alpha: 1).cgColor
        
        addSubview(titleLabel)
        addSubview(exportButton)
        addSubview(listContainer)
        listContainer.addSubview(scrollView)
        scrollView.documentView = listView
    }
    
    // MARK: - Layout
    
    override func layout() {
        super.layout()
        let w = bounds.width
        let h = bounds.height
        guard w > 0, h > 0 else { return }
        
        // header 区域
        let headerH: CGFloat = 28
        let headerY: CGFloat = 20
        let btnW: CGFloat = 110
        
        titleLabel.frame = NSRect(x: 20, y: headerY, width: w - 40 - btnW - 8, height: headerH)
        exportButton.frame = NSRect(x: w - 20 - btnW, y: headerY, width: btnW, height: headerH)
        
        // list 区域
        let listY = headerY + headerH + 16
        let listH = h - listY - 20
        listContainer.frame = NSRect(x: 20, y: listY, width: w - 40, height: listH)
        scrollView.frame = listContainer.bounds
        listView.frame = NSRect(x: 0, y: 0, width: listContainer.bounds.width, height: max(listContainer.bounds.height, 1))
    }
    
    // MARK: - Actions
    
    @objc private func exportButtonClicked() {
        onExportButtonClicked?()
    }
    
    // MARK: - Public Methods
    
    func getListView() -> NSView {
        return listView
    }
    
    func getScrollView() -> NSScrollView {
        return scrollView
    }
}

private final class _FlippedView: NSView {
    override var isFlipped: Bool { true }
}
