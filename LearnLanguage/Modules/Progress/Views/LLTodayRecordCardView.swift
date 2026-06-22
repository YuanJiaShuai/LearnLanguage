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
        button.font = NSFont.inter(13, .medium)
        button.wantsLayer = true
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.surfaceContainerLow.cgColor
        button.layer?.cornerRadius = 6
        button.layer?.borderWidth = 1
        button.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.6).cgColor
        button.contentTintColor = LLAppearanceManager.shared.colors.primaryText
        return button
    }()
    
    private let listContainer: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.cardBackground.cgColor
        view.layer?.cornerRadius = 6
        view.layer?.borderWidth = 1
        view.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.6).cgColor
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
        layer?.backgroundColor = LLAppearanceManager.shared.colors.cardBackground.cgColor
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.6).cgColor
        
        addSubview(titleLabel)
        addSubview(exportButton)
        addSubview(listContainer)
        listContainer.addSubview(scrollView)
        scrollView.documentView = listView

        titleLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(20)
            make.trailing.lessThanOrEqualTo(exportButton.snp.leading).offset(-8)
            make.height.equalTo(28)
        }

        exportButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().inset(20)
            make.size.equalTo(CGSize(width: 110, height: 28))
        }

        listContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.bottom.equalToSuperview().inset(20)
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        listView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
            make.height.greaterThanOrEqualTo(scrollView)
        }
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
