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
    
    private lazy var leftBar: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        view.isHidden = true
        return view
    }()
    
    private lazy var iconView: NSImageView = {
        let imageView = NSImageView()
        if let icon = module.icon {
            icon.isTemplate = true
            icon.size = NSSize(width: 16, height: 16)
            imageView.image = icon
        }
        imageView.imageScaling = .scaleProportionallyDown
        return imageView
    }()
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: module.title)
        label.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        return label
    }()
    
    // MARK: - Initialization
    
    init(module: SidebarModule) {
        self.module = module
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        
        addSubview(leftBar)
        addSubview(iconView)
        addSubview(titleLabel)
        
        leftBar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(3)
        }
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
        }
        
        // 添加点击手势
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(clickGesture)
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    private func updateAppearance() {
        let colors = LLAppearanceManager.shared.colors
        layer?.backgroundColor = isSelected ? colors.accentLightBackground.cgColor : NSColor.clear.cgColor
        leftBar.isHidden = !isSelected
        let tintColor = isSelected ? colors.accentColor : colors.primaryText
        iconView.contentTintColor = tintColor
        titleLabel.textColor = tintColor
    }
}
