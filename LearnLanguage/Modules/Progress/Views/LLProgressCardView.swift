//
//  LLProgressCardView.swift
//  LearnLanguage
//
//  进度卡片视图

import AppKit
import SnapKit

final class LLProgressCardView: NSView {
    private let iconView: NSImageView = {
        let imageView = NSImageView(image: NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: nil) ?? NSImage())
        imageView.imageScaling = .scaleProportionallyDown
        imageView.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        return imageView
    }()

    private let iconContainer = NSView()
    
    private let numberLabel: NSTextField = {
        let label = NSTextField(labelWithString: "0/0")
        label.font = NSFont.interDisplay(30, .bold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .left
        return label
    }()
    
    private let descLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Today's Progress", comment: ""))
        label.font = NSFont.inter(13, .semiBold)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .left
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
    
    private let progressBar: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.surfaceContainer.cgColor
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
    
    private var progressRatio: CGFloat = 0
    private var progressFillWidthConstraint: Constraint?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
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
        addSubview(progressBar)
        progressBar.addSubview(progressFill)

        iconContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(18)
            make.centerY.equalToSuperview().offset(-2)
            make.size.equalTo(34)
        }

        iconView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }

        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(18)
            make.top.equalToSuperview().offset(16)
            make.height.equalTo(18)
        }

        numberLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(descLabel)
            make.top.equalTo(descLabel.snp.bottom).offset(4)
            make.height.equalTo(34)
        }

        detailLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(descLabel)
            make.top.equalTo(numberLabel.snp.bottom)
            make.height.equalTo(14)
        }

        progressBar.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(18)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(6)
        }

        progressFill.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            progressFillWidthConstraint = make.width.equalTo(0).constraint
        }
    }
    
    func updateProgress(current: Int, total: Int) {
        numberLabel.stringValue = "\(current)/\(total)"
        progressRatio = total > 0 ? min(1.0, CGFloat(current) / CGFloat(total)) : 0
        let percent = total > 0 ? Int(round((Double(current) / Double(total)) * 100)) : 0
        detailLabel.stringValue = percent >= 100 ? NSLocalizedString("Goal Completed", comment: "") : "\(percent)%"
        progressFillWidthConstraint?.update(offset: progressBar.bounds.width * progressRatio)
        needsLayout = true
    }

    override func layout() {
        super.layout()
        progressFillWidthConstraint?.update(offset: progressBar.bounds.width * progressRatio)
    }
}
