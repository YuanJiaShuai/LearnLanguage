//
//  LLSidebarNavigationItemView.swift
//  LearnLanguage
//
//  侧边栏导航项视图
//

import AppKit
import SnapKit

final class LLSidebarNavigationItemView: NSView {
    
    private let module: SidebarModule
    var onTap: (() -> Void)?
    
    var isSelected: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    // MARK: - UI Components
    
    private lazy var contentView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 12
        return view
    }()
    
    private lazy var iconView: NSImageView = {
        let imageView = NSImageView()
        if let icon = module.icon {
            icon.isTemplate = true
            icon.size = NSSize(width: 18, height: 18)
            imageView.image = icon
        }
        imageView.imageScaling = .scaleProportionallyDown
        return imageView
    }()
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: module.title)
        label.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.lineBreakMode = .byTruncatingTail
        label.maximumNumberOfLines = 1
        return label
    }()
    
    // MARK: - Initialization
    
    init(module: SidebarModule) {
        self.module = module
        super.init(frame: .zero)
        setupUI()
        updateAppearance()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        
        addSubview(contentView)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(NSEdgeInsets(top: 2, left: 10, bottom: 2, right: 10))
            make.height.equalTo(41)
        }
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
        }
        
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(clickGesture)
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    private func updateAppearance() {
        let colors = LLAppearanceManager.shared.colors
        contentView.layer?.backgroundColor = isSelected ? colors.accentLightBackground.withAlphaComponent(0.9).cgColor : NSColor.clear.cgColor
        let tintColor = isSelected ? colors.accentColor : colors.secondaryText
        iconView.contentTintColor = tintColor
        titleLabel.textColor = tintColor
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: isSelected ? .semibold : .medium)
    }
}
