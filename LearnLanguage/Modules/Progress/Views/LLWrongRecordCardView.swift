//
//  LLWrongRecordCardView.swift
//  LearnLanguage
//
//  错题记录卡片视图

import AppKit
import SnapKit

final class LLWrongRecordCardView: NSView {
    
    // MARK: - UI Components
    
    private let iconLabel: NSTextField = {
        let label = NSTextField(labelWithString: "❌")
        label.font = NSFont.systemFont(ofSize: 15)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Wrong Records Title", comment: ""))
        label.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private let countLabel: NSTextField = {
        let label = NSTextField(labelWithString: "0")
        label.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = NSColor(srgbRed: 1.0, green: 0.23, blue: 0.19, alpha: 1)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private let titleLabel2: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Wrong Records Suffix", comment: ""))
        label.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var batchReviewButton: NSButton = {
        let button = NSButton(title: NSLocalizedString("Batch Review", comment: ""), target: self, action: #selector(batchReviewButtonClicked))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        button.layer?.cornerRadius = 6
        button.contentTintColor = .white
        button.font = NSFont.systemFont(ofSize: 13, weight: .medium)
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
    
    var onBatchReviewButtonClicked: (() -> Void)?
    
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
        
        // 标题容器
        let titleContainer = NSView()
        titleContainer.wantsLayer = true
        headerContainer.addSubview(titleContainer)
        titleContainer.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        titleContainer.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        titleContainer.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconLabel.snp.trailing)
            make.centerY.equalToSuperview()
        }
        
        titleContainer.addSubview(countLabel)
        countLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing)
            make.centerY.equalToSuperview()
        }
        
        titleContainer.addSubview(titleLabel2)
        titleLabel2.snp.makeConstraints { make in
            make.leading.equalTo(countLabel.snp.trailing)
            make.centerY.trailing.equalToSuperview()
        }
        
        // 批量复习按钮
        headerContainer.addSubview(batchReviewButton)
        batchReviewButton.snp.makeConstraints { make in
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
    
    @objc private func batchReviewButtonClicked() {
        onBatchReviewButtonClicked?()
    }
    
    // MARK: - Public Methods
    
    func updateCount(_ count: Int) {
        countLabel.stringValue = "\(count)"
    }
    
    func getListView() -> NSView {
        return listView
    }
    
    func getScrollView() -> NSScrollView {
        return scrollView
    }
}

