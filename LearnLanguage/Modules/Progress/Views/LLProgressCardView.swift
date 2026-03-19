//
//  LLProgressCardView.swift
//  LearnLanguage
//
//  进度卡片视图

import AppKit
import SnapKit

final class LLProgressCardView: NSView {
    
    // MARK: - UI Components
    
    private let iconLabel: NSTextField = {
        let label = NSTextField(labelWithString: "✅")
        label.font = NSFont.systemFont(ofSize: 20)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let numberLabel: NSTextField = {
        let label = NSTextField(labelWithString: "0/0")
        label.font = NSFont.systemFont(ofSize: 26, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.accentColor
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let descLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Today's Progress", comment: ""))
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .center
        return label
    }()
    
    private let progressBar: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(srgbRed: 0.9, green: 0.9, blue: 0.91, alpha: 1).cgColor
        view.layer?.cornerRadius = 3
        return view
    }()
    
    private let progressFill: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        view.layer?.cornerRadius = 3
        return view
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
        
        addSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-16)
            make.height.equalTo(6)
        }
        
        progressBar.addSubview(progressFill)
        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0)
        }
    }
    
    // MARK: - Public Methods
    
    func updateProgress(current: Int, total: Int) {
        numberLabel.stringValue = "\(current)/\(total)"
        let progress = total > 0 ? min(1.0, CGFloat(current) / CGFloat(total)) : 0
        progressFill.snp.remakeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(progress)
        }
    }
}

