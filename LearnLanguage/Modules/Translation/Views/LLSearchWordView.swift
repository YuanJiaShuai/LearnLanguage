//
//  LLSearchWordView.swift
//  LearnLanguage
//
//  状态栏下拉菜单中的查词视图 - 纯 AppKit 实现
//

import AppKit
import SnapKit

final class LLSearchWordView: NSView {

    // MARK: - Constants

    static let viewWidth: CGFloat  = 280
    static let viewHeight: CGFloat = 48  // 初始高度：top(8) + inputContainer(32) + bottom(8)

    // MARK: - UI

    private lazy var inputContainer: NSView = {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.cornerRadius = 7
        v.layer?.borderWidth = 1
        return v
    }()

    private lazy var searchIcon: NSImageView = {
        let iv = NSImageView()
        iv.image = NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil)
        iv.contentTintColor = .tertiaryLabelColor
        return iv
    }()

    private lazy var searchField: NSTextField = {
        let tf = NSTextField()
        tf.isBezeled = false
        tf.drawsBackground = false
        tf.focusRingType = .none
        tf.font = NSFont.systemFont(ofSize: 13)
        tf.placeholderString = "查词（回车翻译）"
        tf.delegate = self
        return tf
    }()

    private lazy var clearButton: NSButton = {
        let btn = NSButton()
        btn.isBordered = false
        btn.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "清空")
        btn.contentTintColor = .tertiaryLabelColor
        btn.isHidden = true
        btn.target = self
        btn.action = #selector(clearSearch)
        return btn
    }()

    private lazy var loadingIndicator: NSProgressIndicator = {
        let pi = NSProgressIndicator()
        pi.style = .spinning
        pi.controlSize = .small
        pi.isHidden = true
        return pi
    }()

    private lazy var divider: NSBox = {
        let box = NSBox()
        box.boxType = .separator
        box.isHidden = true
        return box
    }()

    private lazy var resultContainer: NSView = {
        let v = NSView()
        v.isHidden = true
        return v
    }()

    private lazy var phoneticLabel: NSTextField = {
        let tf = NSTextField(labelWithString: "")
        tf.font = NSFont.systemFont(ofSize: 11)
        tf.textColor = .tertiaryLabelColor
        tf.isHidden = true
        return tf
    }()

    private lazy var resultLabel: NSTextField = {
        let tf = NSTextField(wrappingLabelWithString: "")
        tf.font = NSFont.systemFont(ofSize: 13)
        tf.textColor = .secondaryLabelColor
        tf.maximumNumberOfLines = 5
        tf.isSelectable = true
        return tf
    }()

    private lazy var speakButton: NSButton = {
        let btn = NSButton()
        btn.isBordered = false
        btn.image = NSImage(systemSymbolName: "speaker.wave.2", accessibilityDescription: "朗读")
        btn.contentTintColor = .tertiaryLabelColor
        btn.isHidden = true
        btn.target = self
        btn.action = #selector(speakWord)
        return btn
    }()

    // MARK: - State

    private var lastSearchedText = ""

    /// 高度变化回调，菜单项需要监听此回调来更新尺寸
    var onHeightChanged: ((CGFloat) -> Void)?

    // MARK: - Init

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupUI()
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        updateAppearance()
    }

    // MARK: - Setup

    private func setupUI() {
        // 输入框容器
        addSubview(inputContainer)
        inputContainer.addSubview(searchIcon)
        inputContainer.addSubview(searchField)
        inputContainer.addSubview(clearButton)
        inputContainer.addSubview(loadingIndicator)

        inputContainer.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.equalTo(32)
        }

        searchIcon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(13)
        }

        searchField.snp.makeConstraints { make in
            make.leading.equalTo(searchIcon.snp.trailing).offset(6)
            make.trailing.equalTo(clearButton.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
        }

        clearButton.snp.makeConstraints { make in
            make.trailing.equalTo(loadingIndicator.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14)
        }

        // 分割线
        addSubview(divider)
        divider.snp.makeConstraints { make in
            make.top.equalTo(inputContainer.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }

        // 结果区域
        addSubview(resultContainer)
        resultContainer.addSubview(phoneticLabel)
        resultContainer.addSubview(resultLabel)
        resultContainer.addSubview(speakButton)

        resultContainer.snp.makeConstraints { make in
            make.top.equalTo(divider.snp.bottom).offset(8)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }

        speakButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.height.equalTo(20)
        }

        phoneticLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.equalToSuperview()
            make.trailing.equalTo(speakButton.snp.leading).offset(-4)
        }

        resultLabel.snp.makeConstraints { make in
            make.top.equalTo(phoneticLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Appearance

    private func updateAppearance() {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        inputContainer.layer?.backgroundColor = (isDark
            ? NSColor.white.withAlphaComponent(0.08)
            : NSColor.black.withAlphaComponent(0.05)).cgColor
        inputContainer.layer?.borderColor = (isDark
            ? NSColor.white.withAlphaComponent(0.12)
            : NSColor.black.withAlphaComponent(0.1)).cgColor
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateAppearance()
    }

    // MARK: - Actions

    @objc private func clearSearch() {
        searchField.stringValue = ""
        lastSearchedText = ""
        clearButton.isHidden = true
        hideResult()
        LLSpeechService.shared.stop()
    }

    @objc private func speakWord() {
        let word = lastSearchedText
        guard !word.isEmpty else { return }
        let lang = LLSettingsStore.shared.currentLanguage.speechLanguageCode
        LLSpeechService.shared.speak(word, language: lang)
    }

    // MARK: - Search

    private func performSearch() {
        let text = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard text != lastSearchedText else { return }

        lastSearchedText = text
        showLoading(true)
        hideResult()

        // 根据当前学习语言自动选择翻译方向
        let direction = LLSettingsStore.shared.currentLanguage.translationDirection

        LLTranslationManager.shared.translate(text, direction: direction) { [weak self] result in
            guard let self else { return }
            self.showLoading(false)

            switch result {
            case .success(let r):
                self.showResult(translated: r.translatedText, phonetics: r.phonetics)
            case .failure(let error):
                self.showResult(translated: error.localizedDescription, phonetics: nil)
            }
        }
    }

    // MARK: - UI State

    private func showLoading(_ loading: Bool) {
        if loading {
            loadingIndicator.isHidden = false
            loadingIndicator.startAnimation(nil)
        } else {
            loadingIndicator.stopAnimation(nil)
            loadingIndicator.isHidden = true
        }
    }

    private func showResult(translated: String, phonetics: String?) {
        resultLabel.stringValue = translated

        if let p = phonetics, !p.isEmpty {
            phoneticLabel.stringValue = p
            phoneticLabel.isHidden = false
        } else {
            phoneticLabel.stringValue = ""
            phoneticLabel.isHidden = true
        }

        speakButton.isHidden = false
        divider.isHidden = false
        resultContainer.isHidden = false

        // 通知父级更新高度
        DispatchQueue.main.async {
            self.layoutSubtreeIfNeeded()
            let newHeight = self.calculatedHeight()
            self.onHeightChanged?(newHeight)
        }
    }

    /// 根据当前内容计算视图所需总高度
    private func calculatedHeight() -> CGFloat {
        // 输入框区域：top 8 + 高度 32 + bottom 8 = 48（固定）
        let inputH: CGFloat = 48

        // 没有结果时直接返回输入框高度
        guard !resultContainer.isHidden else { return inputH }

        // 分割线：8（间距）+ 1（线）= 9
        let dividerH: CGFloat = 9

        // 音标行高度（隐藏时为 0，且不计 resultLabel top 的 4pt offset）
        let phoneticH: CGFloat
        if phoneticLabel.isHidden || phoneticLabel.stringValue.isEmpty {
            phoneticH = 0
        } else {
            phoneticH = phoneticLabel.fittingSize.height + 4  // +4 = resultLabel top offset
        }

        // 翻译结果文字高度（按宽度换行，最多 5 行）
        let labelWidth = LLSearchWordView.viewWidth - 24  // leading 12 + trailing 12
        let font = resultLabel.font ?? NSFont.systemFont(ofSize: 13)
        let singleLineH = "A".boundingRect(
            with: CGSize(width: labelWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height
        let maxResultH = ceil(singleLineH) * 5  // maximumNumberOfLines = 5

        let resultH: CGFloat
        let text = resultLabel.stringValue
        if text.isEmpty {
            resultH = ceil(singleLineH)  // 至少保留一行高度
        } else {
            let rect = text.boundingRect(
                with: CGSize(width: labelWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: font],
                context: nil
            )
            resultH = min(ceil(rect.height), maxResultH)
        }

        // 结果容器：top 8 + (phonetic含间距 或 0) + result + bottom 8
        // 注意：phoneticLabel 隐藏时 resultLabel top 约束仍有 4pt，需额外补上
        let topGap: CGFloat = phoneticH > 0 ? 0 : 4  // phoneticLabel.bottom + 4 = resultLabel.top
        let resultContainerH: CGFloat = 8 + phoneticH + topGap + resultH + 8

        return inputH + dividerH + resultContainerH
    }

    private func hideResult() {
        resultContainer.isHidden = true
        divider.isHidden = true
        speakButton.isHidden = true
        phoneticLabel.isHidden = true
        resultLabel.stringValue = ""
        onHeightChanged?(LLSearchWordView.viewHeight)
    }

    // MARK: - Focus

    /// 让输入框获取焦点
    func focusSearchField() {
        if let window = self.window {
            window.makeFirstResponder(searchField)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self, let window = self.window else { return }
                window.makeFirstResponder(self.searchField)
            }
        }
    }

    /// 菜单关闭时清理状态
    func reset() {
        searchField.stringValue = ""
        lastSearchedText = ""
        clearButton.isHidden = true
        LLSpeechService.shared.stop()
        hideResult()
    }
}

// MARK: - NSTextFieldDelegate

extension LLSearchWordView: NSTextFieldDelegate {

    func controlTextDidChange(_ obj: Notification) {
        let text = searchField.stringValue
        clearButton.isHidden = text.isEmpty
        // 输入变化时重置 lastSearchedText，允许重新搜索
        if text != lastSearchedText {
            lastSearchedText = ""
        }
        // 文本清空时隐藏结果区域并恢复初始高度
        if text.isEmpty {
            hideResult()
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            performSearch()
            return true
        }
        return false
    }
}
