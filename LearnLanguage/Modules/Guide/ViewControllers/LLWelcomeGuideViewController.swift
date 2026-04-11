import AppKit
import SnapKit

final class LLWelcomeGuideViewController: NSViewController {
    
    struct Page {
        let eyebrow: String
        let title: String
        let subtitle: String
        let symbolName: String
    }
    
    var onFinished: (() -> Void)?
    
    private let pages: [Page] = [
        .init(
            eyebrow: "欢迎使用",
            title: "LearnLanguage",
            subtitle: "围绕词库、生词本和状态栏练习构建的语言学习工具。",
            symbolName: "sparkles.rectangle.stack.fill"
        ),
        .init(
            eyebrow: "核心流程",
            title: "先选词库，再开始学习",
            subtitle: "从词库开始日常学习；遇到不会的词，再沉淀到生词本集中复习。",
            symbolName: "books.vertical.fill"
        ),
        .init(
            eyebrow: "高频入口",
            title: "状态栏学习 + 生词本沉淀",
            subtitle: "日常刷词主要在状态栏完成，搜索翻译和双击复制翻译都可以把单词加入生词本。",
            symbolName: "menubar.rectangle"
        )
    ]
    
    private var currentIndex = 0 {
        didSet { updateUI(animated: true) }
    }
    
    private lazy var cardView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 26
        view.layer?.backgroundColor = NSColor.white.cgColor
        view.layer?.shadowColor = NSColor.black.withAlphaComponent(0.08).cgColor
        view.layer?.shadowOpacity = 1
        view.layer?.shadowRadius = 24
        view.layer?.shadowOffset = CGSize(width: 0, height: -6)
        return view
    }()
    
    private lazy var eyebrowLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.inter(12, .bold)
        label.textColor = LLAppearanceManager.shared.colors.accentColor
        return label
    }()
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(wrappingLabelWithString: "")
        label.font = NSFont.inter(30, .bold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.maximumNumberOfLines = 2
        return label
    }()
    
    private lazy var subtitleLabel: NSTextField = {
        let label = NSTextField(wrappingLabelWithString: "")
        label.font = NSFont.inter(15, .medium)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.78)
        label.maximumNumberOfLines = 3
        return label
    }()
    
    private lazy var symbolWrapView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 28
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentLightBackground.cgColor
        return view
    }()
    
    private lazy var symbolView: NSImageView = {
        let view = NSImageView()
        view.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        return view
    }()
    
    private lazy var pageIndicatorLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.inter(12, .semiBold)
        label.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.55)
        return label
    }()
    
    private lazy var skipButton: NSButton = {
        let button = NSButton(title: "跳过", target: self, action: #selector(skipTapped))
        button.isBordered = false
        button.font = NSFont.inter(13, .semiBold)
        button.contentTintColor = LLAppearanceManager.shared.colors.secondaryText
        return button
    }()
    
    private lazy var backButton: NSButton = {
        let button = NSButton(title: "上一步", target: self, action: #selector(backTapped))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = NSFont.inter(13, .semiBold)
        button.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        button.wantsLayer = true
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentLightBackground.cgColor
        button.layer?.cornerRadius = 10
        return button
    }()
    
    private lazy var nextButton: NSButton = {
        let button = NSButton(title: "下一步", target: self, action: #selector(nextTapped))
        button.bezelStyle = .rounded
        button.isBordered = false
        button.font = NSFont.inter(13, .semiBold)
        button.contentTintColor = .white
        button.wantsLayer = true
        button.layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        button.layer?.cornerRadius = 10
        return button
    }()
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 620, height: 420))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        updateUI(animated: false)
    }
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor(calibratedWhite: 0.96, alpha: 1).cgColor
        
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(24)
        }
        
        cardView.addSubview(skipButton)
        cardView.addSubview(symbolWrapView)
        symbolWrapView.addSubview(symbolView)
        cardView.addSubview(eyebrowLabel)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(pageIndicatorLabel)
        cardView.addSubview(backButton)
        cardView.addSubview(nextButton)
        
        skipButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.right.equalToSuperview().offset(-18)
        }
        
        symbolWrapView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(52)
            make.left.equalToSuperview().offset(28)
            make.width.height.equalTo(88)
        }
        
        symbolView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(42)
        }
        
        eyebrowLabel.snp.makeConstraints { make in
            make.top.equalTo(symbolWrapView.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(28)
            make.right.equalToSuperview().offset(-28)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(eyebrowLabel.snp.bottom).offset(10)
            make.left.equalToSuperview().offset(28)
            make.right.equalToSuperview().offset(-28)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(28)
            make.right.equalToSuperview().offset(-28)
        }
        
        pageIndicatorLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(28)
            make.bottom.equalToSuperview().offset(-24)
        }
        
        nextButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-28)
            make.bottom.equalToSuperview().offset(-18)
            make.width.equalTo(108)
            make.height.equalTo(40)
        }
        
        backButton.snp.makeConstraints { make in
            make.right.equalTo(nextButton.snp.left).offset(-10)
            make.centerY.equalTo(nextButton)
            make.width.equalTo(92)
            make.height.equalTo(40)
        }
    }
    
    private func updateUI(animated: Bool) {
        let page = pages[currentIndex]
        let updates = {
            self.eyebrowLabel.stringValue = page.eyebrow
            self.titleLabel.stringValue = page.title
            self.subtitleLabel.stringValue = page.subtitle
            self.symbolView.image = NSImage(systemSymbolName: page.symbolName, accessibilityDescription: nil)
            self.pageIndicatorLabel.stringValue = "\(self.currentIndex + 1) / \(self.pages.count)"
            self.backButton.isHidden = self.currentIndex == 0
            self.nextButton.title = self.currentIndex == self.pages.count - 1 ? "开始使用" : "下一步"
        }
        
        guard animated else {
            updates()
            return
        }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            self.titleLabel.animator().alphaValue = 0.4
            self.subtitleLabel.animator().alphaValue = 0.4
        } completionHandler: {
            updates()
            self.titleLabel.alphaValue = 0.4
            self.subtitleLabel.alphaValue = 0.4
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                self.titleLabel.animator().alphaValue = 1
                self.subtitleLabel.animator().alphaValue = 1
            }
        }
    }
    
    @objc private func skipTapped() {
        finishGuide()
    }
    
    @objc private func backTapped() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }
    
    @objc private func nextTapped() {
        if currentIndex >= pages.count - 1 {
            finishGuide()
        } else {
            currentIndex += 1
        }
    }
    
    private func finishGuide() {
        LLGuideManager.shared.markWelcomeGuideCompleted()
        dismiss(self)
        onFinished?()
    }
}
