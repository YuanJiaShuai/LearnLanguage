//
//  LLSettingsCardView.swift
//  LearnLanguage
//
//  设置卡片视图组件

import AppKit
import SnapKit

final class LLSettingsCardView: NSView {
    
    // MARK: - UI Components
    
    private lazy var containerView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(white: 0.98, alpha: 1.0).cgColor
        view.layer?.cornerRadius = 8
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor(white: 0.9, alpha: 1.0).cgColor
        return view
    }()
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = NSColor(white: 0.2, alpha: 1.0)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var iconLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 14)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private lazy var contentStackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 16
        stack.alignment = .leading
        stack.distribution = .fill
        stack.setHuggingPriority(.required, for: .vertical)
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        return stack
    }()
    
    // MARK: - Initialization
    
    init(title: String, icon: String = "") {
        super.init(frame: .zero)
        titleLabel.stringValue = title
        iconLabel.stringValue = icon
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        
        addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let titleStack = NSStackView(views: [iconLabel, titleLabel])
        titleStack.orientation = .horizontal
        titleStack.spacing = 8
        titleStack.alignment = .centerY
        
        containerView.addSubview(titleStack)
        titleStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        containerView.addSubview(contentStackView)
        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(titleStack.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview().offset(-20).priority(.high)
        }
    }
    
    // MARK: - Public Methods
    
    func addFormItem(label: String, control: NSView) {
        let itemView = createFormItem(label: label, control: control)
        contentStackView.addArrangedSubview(itemView)
    }
    
    /// 左右水平布局：左边标题，右边控件
    func addFormItemInline(label: String, control: NSView) {
        let itemView = createFormItemInline(label: label, control: control)
        contentStackView.addArrangedSubview(itemView)
        itemView.snp.makeConstraints { make in
            make.width.equalTo(contentStackView)
        }
    }
    
    func addFormRow(items: [(label: String, control: NSView)]) {
        let rowStack = NSStackView()
        rowStack.orientation = .horizontal
        rowStack.spacing = 16
        rowStack.distribution = .fillEqually
        
        for item in items {
            let formItem = createFormItem(label: item.label, control: item.control)
            rowStack.addArrangedSubview(formItem)
        }
        
        contentStackView.addArrangedSubview(rowStack)
        rowStack.snp.makeConstraints { make in
            make.width.equalTo(contentStackView)
        }
    }
    
    private func createFormItem(label: String, control: NSView) -> NSView {
        let container = NSView()
        
        let labelField = NSTextField(labelWithString: label)
        labelField.font = NSFont.systemFont(ofSize: 13)
        labelField.textColor = NSColor(white: 0.4, alpha: 1.0)
        labelField.isEditable = false
        labelField.isBezeled = false
        labelField.drawsBackground = false
        
        container.addSubview(labelField)
        container.addSubview(control)
        
        labelField.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        
        control.snp.makeConstraints { make in
            make.top.equalTo(labelField.snp.bottom).offset(6)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.greaterThanOrEqualTo(28)
        }
        
        return container
    }
    
    private func createFormItemInline(label: String, control: NSView) -> NSView {
        let stack = NSStackView()
        stack.orientation = .horizontal
        stack.spacing = 12
        stack.alignment = .centerY
        stack.distribution = .fill
        
        let labelField = NSTextField(labelWithString: label)
        labelField.font = NSFont.systemFont(ofSize: 13)
        labelField.textColor = NSColor(white: 0.4, alpha: 1.0)
        labelField.isEditable = false
        labelField.isBezeled = false
        labelField.drawsBackground = false
        labelField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        labelField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        control.setContentHuggingPriority(.required, for: .horizontal)
        control.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        stack.addArrangedSubview(labelField)
        stack.addArrangedSubview(control)
        
        stack.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(28)
        }
        
        return stack
    }
}

