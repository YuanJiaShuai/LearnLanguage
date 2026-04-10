//
//  LLSimilarWordsHomeViewController.swift
//  LearnLanguage
//
//  学习实验室 - 相似词练习首页
//

import AppKit
import SnapKit

final class LLSimilarWordsHomeViewController: NSViewController {
    
    private let onBack: () -> Void
    
    init(onBack: @escaping () -> Void) {
        self.onBack = onBack
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1100, height: 620))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        let backButton = NSButton(title: "返回", target: self, action: #selector(onBackTapped))
        backButton.isBordered = false
        backButton.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: nil)
        backButton.imagePosition = .imageLeading
        backButton.contentTintColor = .systemPurple
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().offset(28)
        }
        
        let iconWrap = NSView()
        iconWrap.wantsLayer = true
        iconWrap.layer?.cornerRadius = 16
        iconWrap.layer?.backgroundColor = NSColor.systemPurple.withAlphaComponent(0.12).cgColor
        view.addSubview(iconWrap)
        iconWrap.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(40)
            make.leading.equalToSuperview().offset(40)
            make.width.height.equalTo(72)
        }
        
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "rectangle.3.group.bubble.left.fill", accessibilityDescription: nil)
        iconView.contentTintColor = .systemPurple
        iconWrap.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        let titleLabel = NSTextField(labelWithString: "相似词练习")
        titleLabel.font = NSFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconWrap.snp.bottom).offset(28)
            make.leading.equalToSuperview().offset(40)
        }
        
        let subtitleLabel = NSTextField(labelWithString: "Similar Words")
        subtitleLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        subtitleLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.62)
        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(40)
        }
        
        let card = NSView()
        card.wantsLayer = true
        card.layer?.cornerRadius = 20
        card.layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
        card.layer?.borderWidth = 1
        card.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.4).cgColor
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(28)
            make.leading.trailing.equalToSuperview().inset(40)
            make.bottom.equalToSuperview().offset(-40)
        }
        
        let detailLabel = NSTextField(labelWithString: "这里是独立的相似词练习模块首页。下一步可以从固定词组开始，比如 big / large / huge、say / tell / speak，然后扩展成练习题流程。")
        detailLabel.font = NSFont.systemFont(ofSize: 16, weight: .regular)
        detailLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        detailLabel.lineBreakMode = .byWordWrapping
        detailLabel.maximumNumberOfLines = 0
        card.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(28)
        }
        
        let hintLabel = NSTextField(labelWithString: "后续建议：词组列表 / 练习题页 / 答案反馈")
        hintLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        hintLabel.textColor = NSColor.systemPurple.withAlphaComponent(0.9)
        card.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(detailLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(28)
        }
    }
    
    @objc private func onBackTapped() {
        onBack()
    }
}
