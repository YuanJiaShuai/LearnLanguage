//
//  LLTodayRecordCardView.swift
//  LearnLanguage
//
//  今日学习记录卡片视图

import AppKit
import SnapKit

final class LLTodayRecordCardView: NSView {
    
    // MARK: - UI Components
    
    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "📝 今日学习记录")
        label.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var exportButton: NSButton = {
        let button = NSButton(title: "📄 导出记录", target: self, action: #selector(exportButtonClicked))
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
    
    private let listView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        return view
    }()
    
    // MARK: - Callbacks
    
    var onExportButtonClicked: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = NSColor(srgbRed: 0.98, green: 0.98, blue: 0.97, alpha: 1).cgColor
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.91, alpha: 1).cgColor
        
        // 标题和按钮容器
        let headerContainer = NSView()
        headerContainer.wantsLayer = true
        addSubview(headerContainer)
        headerContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(28)
        }
        
        headerContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        headerContainer.addSubview(exportButton)
        exportButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.height.equalTo(28)
            make.width.greaterThanOrEqualTo(100)
        }
        
        // 列表容器
        addSubview(listContainer)
        listContainer.snp.makeConstraints { make in
            make.top.equalTo(headerContainer.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        listContainer.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        scrollView.documentView = listView
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

