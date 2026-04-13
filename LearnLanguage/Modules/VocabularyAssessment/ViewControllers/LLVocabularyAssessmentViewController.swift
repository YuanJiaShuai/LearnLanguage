//
//  LLVocabularyAssessmentViewController.swift
//  LearnLanguage
//
//  学习实验室 - 词汇量评估首页
//

import AppKit
import SnapKit

final class LLVocabularyAssessmentViewController: NSViewController {
    
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
        backButton.contentTintColor = .systemTeal
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().offset(28)
        }
        
        let iconWrap = NSView()
        iconWrap.wantsLayer = true
        iconWrap.layer?.cornerRadius = 16
        iconWrap.layer?.backgroundColor = NSColor.systemTeal.withAlphaComponent(0.12).cgColor
        view.addSubview(iconWrap)
        iconWrap.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(40)
            make.leading.equalToSuperview().offset(40)
            make.width.height.equalTo(72)
        }
        
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "text.book.closed.fill", accessibilityDescription: nil)
        iconView.contentTintColor = .systemTeal
        iconWrap.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(32)
        }
        
        let titleLabel = NSTextField(labelWithString: "词汇量评估")
        titleLabel.font = NSFont.systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconWrap.snp.bottom).offset(28)
            make.leading.equalToSuperview().offset(40)
        }
        
        let subtitleLabel = NSTextField(labelWithString: "Vocabulary Assessment")
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
        
        let detailLabel = NSTextField(labelWithString: "这里是词汇量评估模块首页。当前会基于内置标准词库抽取题目，适合先做 20 题快速测试。后续可以继续扩展标准测试、结果页分析和错词沉淀能力。")
        detailLabel.font = NSFont.systemFont(ofSize: 16, weight: .regular)
        detailLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        detailLabel.lineBreakMode = .byWordWrapping
        detailLabel.maximumNumberOfLines = 0
        card.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(28)
        }
        
        let hintLabel = NSTextField(labelWithString: "下一步建议：测试首页 / 20题抽题逻辑 / 结果页与错词回流")
        hintLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        hintLabel.textColor = NSColor.systemTeal.withAlphaComponent(0.9)
        card.addSubview(hintLabel)
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(detailLabel.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(28)
        }
        
        let summaryWrap = NSStackView()
        summaryWrap.orientation = .vertical
        summaryWrap.spacing = 12
        summaryWrap.alignment = .leading
        card.addSubview(summaryWrap)
        summaryWrap.snp.makeConstraints { make in
            make.top.equalTo(hintLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(28)
        }
        
        [
            "内置标准词库：当前已筛出 900 个候选评估词",
            "推荐流程：快速测试 20 题，高频 / 中频 / 低频分层抽样",
            "后续可扩展：标准测试、拼写测试、错词加入生词本"
        ].forEach { text in
            let label = NSTextField(labelWithString: "• \(text)")
            label.font = NSFont.systemFont(ofSize: 14, weight: .regular)
            label.textColor = LLAppearanceManager.shared.colors.primaryText.withAlphaComponent(0.86)
            label.lineBreakMode = .byWordWrapping
            label.maximumNumberOfLines = 0
            summaryWrap.addArrangedSubview(label)
        }
        
        let startButton = NSButton(title: "开始设计测试流程", target: nil, action: nil)
        startButton.isEnabled = false
        startButton.bezelStyle = .rounded
        startButton.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        startButton.contentTintColor = .white
        startButton.wantsLayer = true
        startButton.layer?.backgroundColor = NSColor.systemTeal.withAlphaComponent(0.9).cgColor
        startButton.layer?.cornerRadius = 8
        card.addSubview(startButton)
        startButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(28)
            make.bottom.equalToSuperview().offset(-28)
            make.height.equalTo(38)
            make.width.greaterThanOrEqualTo(150)
        }
        
        let helperLabel = NSTextField(labelWithString: "入口已就位，下一步可直接接题目页与抽题逻辑。")
        helperLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        helperLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.72)
        card.addSubview(helperLabel)
        helperLabel.snp.makeConstraints { make in
            make.centerY.equalTo(startButton)
            make.leading.equalTo(startButton.snp.trailing).offset(14)
            make.trailing.lessThanOrEqualToSuperview().offset(-28)
        }
    }
    
    @objc private func onBackTapped() {
        onBack()
    }
}
