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
    
    private lazy var button: NSButton = {
        let btn = NSButton()
        btn.setButtonType(.momentaryPushIn)
        btn.bezelStyle = .rounded
        btn.isBordered = false
        btn.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        btn.title = "  \(module.title)"
        btn.target = self
        btn.action = #selector(handleTap)
        (btn.cell as? NSButtonCell)?.alignment = .left
        
        if let icon = module.icon {
            icon.isTemplate = true
            icon.size = NSSize(width: 16, height: 16)
            btn.image = icon
            btn.imagePosition = .imageLeft
            btn.imageScaling = .scaleProportionallyDown
        }
        
        return btn
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
        addSubview(button)
        
        leftBar.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.width.equalTo(3)
        }
        
        button.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-24)
            make.top.bottom.equalToSuperview()
        }
        
        snp.makeConstraints { make in
            make.height.equalTo(40)
        }
    }
    
    @objc private func handleTap() {
        onTap?()
    }
    
    private func updateAppearance() {
        let colors = LLAppearanceManager.shared.colors
        layer?.backgroundColor = isSelected ? colors.accentLightBackground.cgColor : NSColor.clear.cgColor
        leftBar.isHidden = !isSelected
        button.contentTintColor = isSelected ? colors.accentColor : colors.primaryText
    }
}

