//
//  LLStatCardView.swift
//  LearnLanguage
//
//  统计卡片视图

import AppKit
import SnapKit

final class LLStatCardView: NSView {
    private let iconView: NSImageView = {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyDown
        imageView.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        return imageView
    }()

    private let iconContainer = NSView()
    
    private let numberLabel: NSTextField = {
        let label = NSTextField(labelWithString: "0")
        label.font = NSFont.interDisplay(30, .bold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .left
        return label
    }()
    
    private let descLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.inter(13, .semiBold)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .left
        label.maximumNumberOfLines = 2
        return label
    }()

    private let detailLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.inter(11, .medium)
        label.textColor = LLAppearanceManager.shared.colors.tertiaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .left
        return label
    }()
    
    init(icon: String, description: String, detail: String) {
        super.init(frame: .zero)
        iconView.image = NSImage(systemSymbolName: icon, accessibilityDescription: nil)
        descLabel.stringValue = description
        detailLabel.stringValue = detail
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = LLAppearanceManager.shared.colors.cardBackground.cgColor
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.6).cgColor

        iconContainer.wantsLayer = true
        iconContainer.layer?.cornerRadius = 8
        iconContainer.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentLightBackground.withAlphaComponent(0.55).cgColor

        addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        addSubview(numberLabel)
        addSubview(descLabel)
        addSubview(detailLabel)

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.centerY.equalToSuperview()
            make.size.equalTo(34)
        }

        iconView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(18)
            make.top.equalToSuperview().offset(18)
            make.height.greaterThanOrEqualTo(18)
            make.height.lessThanOrEqualTo(36)
        }

        numberLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(descLabel)
            make.top.equalTo(descLabel.snp.bottom).offset(4)
            make.height.equalTo(36)
        }

        detailLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(descLabel)
            make.top.equalTo(numberLabel.snp.bottom).offset(1)
            make.height.equalTo(16)
            make.bottom.lessThanOrEqualToSuperview().inset(10)
        }
    }
    
    func updateNumber(_ value: String) {
        numberLabel.stringValue = value
    }
}
