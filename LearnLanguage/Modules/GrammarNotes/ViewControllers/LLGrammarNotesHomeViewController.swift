//
//  LLGrammarNotesHomeViewController.swift
//  LearnLanguage
//
//  学习实验室 - 语法笔记首页
//

import AppKit
import SnapKit
import WebKit

private struct LLGrammarArticleMeta: Decodable {
    let id: String
    let title: String
    let subtitle: String
    let order: Int
    let articlePath: String
    let imagesPath: String
}

private final class LLGrammarSidebarItemView: NSView {
    var onTap: (() -> Void)?
    private let titleLabel = NSTextField(labelWithString: "")
    private let subtitleLabel = NSTextField(labelWithString: "")
    private var tracking: NSTrackingArea?
    private var hovered = false

    var isActive = false {
        didSet { updateStyle() }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 12

        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        subtitleLabel.font = .systemFont(ofSize: 11, weight: .medium)
        subtitleLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.68)

        addSubview(titleLabel)
        addSubview(subtitleLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(14)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().offset(-12)
        }

        updateStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking {
            removeTrackingArea(tracking)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        tracking = area
    }

    func configure(with item: LLGrammarArticleMeta) {
        titleLabel.stringValue = item.title
        subtitleLabel.stringValue = item.subtitle
    }

    private func updateStyle() {
        if isActive {
            layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.14).cgColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.systemBlue.withAlphaComponent(0.18).cgColor
        } else if hovered {
            layer?.backgroundColor = NSColor.black.withAlphaComponent(0.035).cgColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.clear.cgColor
        } else {
            layer?.backgroundColor = NSColor.clear.cgColor
            layer?.borderWidth = 1
            layer?.borderColor = NSColor.clear.cgColor
        }
    }

    override func mouseEntered(with event: NSEvent) {
        hovered = true
        updateStyle()
    }

    override func mouseExited(with event: NSEvent) {
        hovered = false
        updateStyle()
    }

    override func mouseDown(with event: NSEvent) {
        onTap?()
    }
}

final class LLGrammarNotesHomeViewController: NSViewController {
    private let onBack: () -> Void
    private var articles: [LLGrammarArticleMeta] = []
    private var sidebarItems: [String: LLGrammarSidebarItemView] = [:]

    private let sidebarContainer = NSView()
    private let sidebarScrollView = NSScrollView()
    private let sidebarContentView = NSView()
    private let sidebarStackView = NSStackView()
    private let contentContainer = NSView()
    private let articleTitleLabel = NSTextField(labelWithString: "")
    private let articleSubtitleLabel = NSTextField(labelWithString: "")
    private let webView = WKWebView(frame: .zero)

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
        loadArticles()
        setupUI()
        if let first = articles.first {
            selectArticle(first)
        }
    }

    private func loadArticles() {
        let url = URL(fileURLWithPath: "/Users/admin/Documents/learn/ios/LearnLanguage/LearnLanguage/Modules/GrammarNotes/Resources/grammar-index.json")
        guard let data = try? Data(contentsOf: url) else { return }
        let decoded = (try? JSONDecoder().decode([LLGrammarArticleMeta].self, from: data)) ?? []
        articles = decoded.sorted { $0.order < $1.order }
    }

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor

        let backButton = NSButton(title: "返回", target: self, action: #selector(onBackTapped))
        backButton.isBordered = false
        backButton.font = .systemFont(ofSize: 14, weight: .semibold)
        backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: nil)
        backButton.imagePosition = .imageLeading
        backButton.contentTintColor = .systemBlue
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().offset(28)
        }

        let titleLabel = NSTextField(labelWithString: "语法笔记")
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(32)
        }

        let subtitleLabel = NSTextField(labelWithString: "左侧目录，右侧正文")
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.7)
        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(32)
        }

        let splitContainer = NSView()
        view.addSubview(splitContainer)
        splitContainer.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalToSuperview().offset(-24)
        }

        sidebarContainer.wantsLayer = true
        sidebarContainer.layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
        sidebarContainer.layer?.cornerRadius = 18
        sidebarContainer.layer?.borderWidth = 1
        sidebarContainer.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.4).cgColor
        splitContainer.addSubview(sidebarContainer)
        sidebarContainer.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(280)
        }

        let sidebarHeader = NSTextField(labelWithString: "语法目录")
        sidebarHeader.font = .systemFont(ofSize: 14, weight: .bold)
        sidebarHeader.textColor = LLAppearanceManager.shared.colors.primaryText
        sidebarContainer.addSubview(sidebarHeader)
        sidebarHeader.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(18)
        }

        sidebarScrollView.drawsBackground = false
        sidebarScrollView.borderType = .noBorder
        sidebarScrollView.hasVerticalScroller = true
        sidebarScrollView.autohidesScrollers = true
        sidebarScrollView.documentView = sidebarContentView
        sidebarContainer.addSubview(sidebarScrollView)
        sidebarScrollView.snp.makeConstraints { make in
            make.top.equalTo(sidebarHeader.snp.bottom).offset(14)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        sidebarStackView.orientation = .vertical
        sidebarStackView.spacing = 10
        sidebarStackView.alignment = .leading
        sidebarContentView.addSubview(sidebarStackView)
        sidebarStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(sidebarScrollView.contentView)
        }

        contentContainer.wantsLayer = true
        contentContainer.layer?.backgroundColor = NSColor.white.cgColor
        contentContainer.layer?.cornerRadius = 18
        contentContainer.layer?.borderWidth = 1
        contentContainer.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.4).cgColor
        splitContainer.addSubview(contentContainer)
        contentContainer.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.leading.equalTo(sidebarContainer.snp.trailing).offset(18)
        }

        articleTitleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        articleTitleLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        contentContainer.addSubview(articleTitleLabel)
        articleTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(22)
        }

        articleSubtitleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        articleSubtitleLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.68)
        contentContainer.addSubview(articleSubtitleLabel)
        articleSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(articleTitleLabel.snp.bottom).offset(6)
            make.leading.equalToSuperview().offset(22)
        }

        let divider = NSView()
        divider.wantsLayer = true
        divider.layer?.backgroundColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.5).cgColor
        contentContainer.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.top.equalTo(articleSubtitleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        webView.setValue(false, forKey: "drawsBackground")
        contentContainer.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }

        buildSidebarItems()
    }

    private func buildSidebarItems() {
        sidebarStackView.arrangedSubviews.forEach {
            sidebarStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        sidebarItems.removeAll()

        for article in articles {
            let item = LLGrammarSidebarItemView()
            item.configure(with: article)
            item.onTap = { [weak self] in
                self?.selectArticle(article)
            }
            sidebarStackView.addArrangedSubview(item)
            item.snp.makeConstraints { make in
                make.width.equalToSuperview()
            }
            sidebarItems[article.id] = item
        }
    }

    private func selectArticle(_ article: LLGrammarArticleMeta) {
        articleTitleLabel.stringValue = article.title
        articleSubtitleLabel.stringValue = article.subtitle
        sidebarItems.forEach { key, view in
            view.isActive = (key == article.id)
        }
        loadArticle(article)
    }

    private func loadArticle(_ article: LLGrammarArticleMeta) {
        let root = URL(fileURLWithPath: "/Users/admin/Documents/learn/ios/LearnLanguage/LearnLanguage/Modules/GrammarNotes/Resources", isDirectory: true)
        let articleURL = root.appendingPathComponent(article.articlePath)
        guard let markdown = try? String(contentsOf: articleURL, encoding: .utf8) else {
            webView.loadHTMLString("<html><body><p>内容加载失败</p></body></html>", baseURL: root)
            return
        }
        webView.loadHTMLString(buildHTML(from: markdown), baseURL: articleURL.deletingLastPathComponent())
    }

    private func buildHTML(from markdown: String) -> String {
        let body = renderMarkdownBody(from: markdown)
        return """
        <!doctype html>
        <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body { margin: 0; padding: 28px 32px 48px; font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', sans-serif; color: #1f2937; background: #ffffff; line-height: 1.8; font-size: 16px; }
            h1, h2, h3 { color: #111827; line-height: 1.25; margin: 0 0 16px; }
            h1 { font-size: 30px; }
            h2 { font-size: 24px; margin-top: 28px; }
            h3 { font-size: 20px; margin-top: 24px; }
            p { margin: 0 0 14px; }
            img { display: block; max-width: 100%; height: auto; margin: 18px auto; border-radius: 14px; box-shadow: 0 10px 30px rgba(15, 23, 42, 0.08); }
            blockquote { margin: 18px 0; padding: 10px 14px; border-left: 4px solid rgba(59, 130, 246, 0.35); background: rgba(59, 130, 246, 0.06); border-radius: 8px; }
            code { background: rgba(15, 23, 42, 0.06); padding: 2px 6px; border-radius: 6px; font-size: 0.94em; }
            strong { color: #111827; }
            em { color: #334155; }
          </style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }

    private func renderMarkdownBody(from markdown: String) -> String {
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")
        let blocks = normalized.components(separatedBy: "\n\n")
        return blocks.map { renderMarkdownBlock($0) }.joined(separator: "\n")
    }

    private func renderMarkdownBlock(_ block: String) -> String {
        let trimmed = block.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        if trimmed.hasPrefix("<") {
            return trimmed
        }

        if trimmed.hasPrefix("### ") {
            return "<h3>\(renderInlineMarkdown(String(trimmed.dropFirst(4))))</h3>"
        }

        if trimmed.hasPrefix("## ") {
            return "<h2>\(renderInlineMarkdown(String(trimmed.dropFirst(3))))</h2>"
        }

        if trimmed.hasPrefix("# ") {
            return "<h1>\(renderInlineMarkdown(String(trimmed.dropFirst(2))))</h1>"
        }

        if trimmed.hasPrefix(">") {
            let quote = trimmed
                .split(separator: "\n")
                .map { line in
                    let text = line.trimmingCharacters(in: CharacterSet(charactersIn: "> "))
                    return renderInlineMarkdown(text)
                }
                .joined(separator: "<br>")
            return "<blockquote>\(quote)</blockquote>"
        }

        let lines = trimmed
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { renderInlineMarkdown(String($0)) }
            .joined(separator: "<br>")
        return "<p>\(lines)</p>"
    }

    private func renderInlineMarkdown(_ text: String) -> String {
        var html = escapeHTML(text)
        html = html.replacingOccurrences(of: "`([^`]+)`", with: "<code>$1</code>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*\\*([^*]+)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*([^*]+)\\*", with: "<em>$1</em>", options: .regularExpression)
        return html
    }

    private func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    @objc private func onBackTapped() {
        onBack()
    }
}
