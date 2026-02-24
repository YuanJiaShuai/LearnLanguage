//
//  LLTrendCardView.swift
//  LearnLanguage
//
//  学习趋势图表卡片视图

import AppKit
import SnapKit

final class LLTrendCardView: NSView {
    
    // MARK: - UI Components
    
    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "📊 近7天学习趋势")
        label.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private let chartPlaceholder: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(srgbRed: 0.94, green: 0.94, blue: 0.96, alpha: 1).cgColor
        view.layer?.cornerRadius = 8
        return view
    }()
    
    private let placeholderText: NSTextField = {
        let label = NSTextField(labelWithString: "📊 学习曲线图表（开发中）")
        label.font = NSFont.systemFont(ofSize: 14)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
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
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        addSubview(chartPlaceholder)
        chartPlaceholder.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        chartPlaceholder.addSubview(placeholderText)
        placeholderText.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

