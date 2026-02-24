//
//  LLStatCardView.swift
//  LearnLanguage
//
//  统计卡片视图

import AppKit
import SnapKit

final class LLStatCardView: NSView {
    
    // MARK: - UI Components
    
    private let iconLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 20)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let numberLabel: NSTextField = {
        let label = NSTextField(labelWithString: "0")
        label.font = NSFont.systemFont(ofSize: 26, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.accentColor
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let descLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    // MARK: - Initialization
    
    init(icon: String, description: String) {
        super.init(frame: .zero)
        iconLabel.stringValue = icon
        descLabel.stringValue = description
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
        
        addSubview(iconLabel)
        iconLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(16)
        }
        
        addSubview(numberLabel)
        numberLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconLabel.snp.bottom).offset(6)
        }
        
        addSubview(descLabel)
        descLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(numberLabel.snp.bottom).offset(4)
        }
    }
    
    // MARK: - Public Methods
    
    func updateNumber(_ value: String) {
        numberLabel.stringValue = value
    }
}

