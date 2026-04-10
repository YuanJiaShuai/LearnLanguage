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
    private let resourceBundle = Bundle.main
    private var articles: [LLGrammarArticleMeta] = []
    private var sidebarItems: [String: LLGrammarSidebarItemView] = [:]
    private var isSidebarCollapsed = false

    private let sidebarContainer = NSView()
    private let sidebarScrollView = NSScrollView()
    private let sidebarContentView = NSView()
    private let sidebarStackView = NSStackView()
    private let contentContainer = NSView()
    private let webView = WKWebView(frame: .zero)
    private var sidebarWidthConstraint: Constraint?

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
        guard let url = resourceBundle.url(
            forResource: "grammar-index",
            withExtension: "json"
        ), let data = try? Data(contentsOf: url) else {
            return
        }
        let decoded = (try? JSONDecoder().decode([LLGrammarArticleMeta].self, from: data)) ?? []
        articles = decoded.sorted { $0.order < $1.order }
    }

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor

        let backButton = makeFloatingIconButton(symbolName: "chevron.left", action: #selector(onBackTapped))
        view.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(24)
            make.width.height.equalTo(42)
        }

        let pageTitleLabel = NSTextField(labelWithString: "语法笔记")
        pageTitleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        pageTitleLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        view.addSubview(pageTitleLabel)
        pageTitleLabel.snp.makeConstraints { make in
            make.centerY.equalTo(backButton)
            make.leading.equalTo(backButton.snp.trailing).offset(14)
        }

        let splitContainer = NSView()
        view.addSubview(splitContainer)
        splitContainer.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(14)
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
            self.sidebarWidthConstraint = make.width.equalTo(280).constraint
        }

        let sidebarToggleButton = makeFloatingIconButton(symbolName: "sidebar.left", action: #selector(toggleSidebar))
        sidebarContainer.addSubview(sidebarToggleButton)
        sidebarToggleButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(14)
            make.width.height.equalTo(34)
        }

        sidebarScrollView.drawsBackground = false
        sidebarScrollView.borderType = .noBorder
        sidebarScrollView.hasVerticalScroller = true
        sidebarScrollView.autohidesScrollers = true
        sidebarContainer.addSubview(sidebarScrollView)
        sidebarScrollView.snp.makeConstraints { make in
            make.top.equalTo(sidebarToggleButton.snp.bottom).offset(12)
            make.leading.trailing.bottom.equalToSuperview().inset(12)
        }

        sidebarContentView.translatesAutoresizingMaskIntoConstraints = false
        sidebarScrollView.documentView = sidebarContentView
        sidebarContentView.snp.makeConstraints { make in
            make.edges.equalTo(sidebarScrollView.contentView)
            make.width.equalTo(sidebarScrollView.contentView)
        }

        sidebarStackView.orientation = .vertical
        sidebarStackView.spacing = 10
        sidebarStackView.alignment = .leading
        sidebarStackView.distribution = .gravityAreas
        sidebarContentView.addSubview(sidebarStackView)
        sidebarStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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

        webView.setValue(false, forKey: "drawsBackground")
        contentContainer.addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
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
            item.translatesAutoresizingMaskIntoConstraints = false
            item.configure(with: article)
            item.onTap = { [weak self] in
                self?.selectArticle(article)
            }
            sidebarStackView.addArrangedSubview(item)
            item.snp.makeConstraints { make in
                make.width.equalTo(sidebarStackView)
            }
            sidebarItems[article.id] = item
        }
    }

    private func makeFloatingIconButton(symbolName: String, action: Selector) -> NSButton {
        let button = NSButton(title: "", target: self, action: action)
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.wantsLayer = true
        button.layer?.cornerRadius = 21
        button.layer?.backgroundColor = NSColor.white.cgColor
        button.layer?.borderWidth = 1
        button.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.75).cgColor
        button.layer?.shadowColor = NSColor.black.withAlphaComponent(0.08).cgColor
        button.layer?.shadowOpacity = 1
        button.layer?.shadowOffset = CGSize(width: 0, height: -1)
        button.layer?.shadowRadius = 10
        button.contentTintColor = LLAppearanceManager.shared.colors.accentColor
        button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        button.imagePosition = .imageOnly
        return button
    }

    @objc private func toggleSidebar() {
        isSidebarCollapsed.toggle()
        sidebarWidthConstraint?.update(offset: isSidebarCollapsed ? 56 : 280)
        sidebarScrollView.alphaValue = isSidebarCollapsed ? 0 : 1

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.view.layoutSubtreeIfNeeded()
        }
    }

    private func selectArticle(_ article: LLGrammarArticleMeta) {
        sidebarItems.forEach { key, view in
            view.isActive = (key == article.id)
        }
        loadArticle(article)
    }

    private func loadArticle(_ article: LLGrammarArticleMeta) {
        guard let articleURL = bundledResourceURL(forRelativePath: article.articlePath) else {
            webView.loadHTMLString("<html><body><p>内容加载失败</p></body></html>", baseURL: resourceBundle.resourceURL)
            return
        }

        guard let markdown = try? String(contentsOf: articleURL, encoding: .utf8) else {
            webView.loadHTMLString("<html><body><p>内容加载失败</p></body></html>", baseURL: resourceBundle.resourceURL)
            return
        }

        let normalizedMarkdown = rewriteBundledImagePaths(in: markdown)
        webView.loadHTMLString(buildHTML(from: normalizedMarkdown), baseURL: articleURL.deletingLastPathComponent())
    }

    private func bundledResourceURL(forRelativePath relativePath: String) -> URL? {
        if let root = resourceBundle.resourceURL {
            let directURL = root.appendingPathComponent(relativePath)
            if FileManager.default.fileExists(atPath: directURL.path) {
                return directURL
            }
        }

        let fileURL = URL(fileURLWithPath: relativePath)
        let fileName = fileURL.deletingPathExtension().lastPathComponent
        let fileExtension = fileURL.pathExtension.isEmpty ? nil : fileURL.pathExtension
        return resourceBundle.url(forResource: fileName, withExtension: fileExtension)
    }

    private func rewriteBundledImagePaths(in markdown: String) -> String {
        let pattern = #"<img\s+src=\"([^\"]+)\"\s*>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return markdown }

        let nsRange = NSRange(markdown.startIndex..., in: markdown)
        let matches = regex.matches(in: markdown, options: [], range: nsRange).reversed()
        var result = markdown

        for match in matches {
            guard match.numberOfRanges == 2,
                  let srcRange = Range(match.range(at: 1), in: result) else {
                continue
            }

            let src = String(result[srcRange])
            guard let imageURL = bundledResourceURL(forRelativePath: src) else {
                continue
            }

            result.replaceSubrange(srcRange, with: imageURL.absoluteString)
        }

        return result
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
            body { margin: 0; padding: 26px 28px 40px; font-family: -apple-system, BlinkMacSystemFont, 'PingFang SC', sans-serif; color: #1f2937; background: #ffffff; line-height: 1.8; font-size: 16px; }
            h1, h2, h3 { color: #111827; line-height: 1.25; margin: 0 0 16px; }
            h1 { font-size: 28px; }
            h2 { font-size: 22px; margin-top: 26px; }
            h3 { font-size: 18px; margin-top: 22px; }
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
