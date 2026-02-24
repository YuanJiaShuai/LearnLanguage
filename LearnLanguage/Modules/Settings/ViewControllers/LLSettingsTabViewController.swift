//
//  LLSettingsTabViewController.swift
//  LearnLanguage
//

import AppKit
import SnapKit
import LaunchAtLogin

final class LLSettingsTabViewController: NSViewController {

    // MARK: - UI Components
    
    private lazy var scrollView: NSScrollView = {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        return scroll
    }()
    
    private lazy var contentView: NSView = {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "学习设置")
        label.font = NSFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = NSColor(white: 0.11, alpha: 1.0)
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    // 学习目标卡片
    private var newWordsField: NSTextField!
    private var reviewCountField: NSTextField!
    
    // 状态栏设置卡片
    private var statusBarIntervalField: NSTextField!
    private var statusBarDisplayPopup: NSPopUpButton!
    private var statusBarPhoneticCheck: NSButton!
    private var statusBarMaxLengthField: NSTextField!
    private var statusBarShowContentCheck: NSButton!
    private var statusBarContentWidthSlider: NSSlider!
    private var statusBarContentWidthLabel: NSTextField!
    private var showFeedbackButtonsCheck: NSButton!
    
    // 新增：状态栏显示内容细分控制
    private var statusBarShowWordCheck: NSButton!
    private var statusBarShowPhoneticSymbolCheck: NSButton!
    private var statusBarShowMeaningCheck: NSButton!
    private var statusBarAutoScrollCheck: NSButton!
    
    // 复习设置卡片
    private var reviewModePopup: NSPopUpButton!
    private var wrongWordRetryField: NSTextField!
    
    // 发音设置卡片
    private var pronunciationCheck: NSButton!
    private var pronunciationProviderPopup: NSPopUpButton!
    private var pronunciationAccentPopup: NSPopUpButton!
    private var pronunciationRateSlider: NSSlider!
    
    // 浮窗设置卡片
    private var panelAlphaSlider: NSSlider!
    private var panelWidthField: NSTextField!
    private var panelHeightField: NSTextField!
    private var typingPracticeEnabledCheck: NSButton!
    private var typingPracticeShowMeaningCheck: NSButton!
    private var typingInputStylePopup: NSPopUpButton!
    private var autoShowAnswerPopup: NSPopUpButton!
    private var addToWrongBookPopup: NSPopUpButton!
    
    // 快捷键设置卡片
    private var shortcutPlaceholderLabel: NSTextField!
    
    // 其他设置卡片
    private var launchAtLoginCheck: NSButton!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 620, height: 600))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSettings()
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        // 添加标题
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalToSuperview().offset(28)
        }
        
        // 设置滚动视图
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(28)
            make.trailing.equalToSuperview().offset(-28)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        // 创建卡片
        let cardsStack = NSStackView()
        cardsStack.orientation = .vertical
        cardsStack.spacing = 20
        cardsStack.alignment = .leading
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        
        // 1. 学习目标卡片
        let goalCard = createGoalCard()
        cardsStack.addArrangedSubview(goalCard)
        
        // 2. 状态栏设置卡片
        let statusBarCard = createStatusBarCard()
        cardsStack.addArrangedSubview(statusBarCard)
        
        // 3. 复习设置卡片
        let reviewCard = createReviewCard()
        cardsStack.addArrangedSubview(reviewCard)
        
        // 4. 发音设置卡片
        let pronunciationCard = createPronunciationCard()
        cardsStack.addArrangedSubview(pronunciationCard)
        
        // 5. 浮窗设置卡片
        let floatingPanelCard = createFloatingPanelCard()
        cardsStack.addArrangedSubview(floatingPanelCard)
        
        // 6. 快捷键设置卡片
        let shortcutCard = createShortcutCard()
        cardsStack.addArrangedSubview(shortcutCard)
        
        // 7. 其他设置卡片
        let otherCard = createOtherCard()
        cardsStack.addArrangedSubview(otherCard)
        
        contentView.addSubview(cardsStack)
        
        // 设置所有卡片宽度一致
        [goalCard, statusBarCard, reviewCard, pronunciationCard, floatingPanelCard, shortcutCard, otherCard].forEach { card in
            card.snp.makeConstraints { make in
                make.width.equalTo(564)
            }
        }
        
        cardsStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(564)
        }
        
        // 设置 contentView 的约束
        contentView.snp.makeConstraints { make in
            make.width.equalTo(564)
        }
        
        scrollView.documentView = contentView
    }
    
    // MARK: - Create Cards
    
    private func createGoalCard() -> LLSettingsCardView {
        let card = LLSettingsCardView(title: "学习目标", icon: "🎯")
        
        newWordsField = createNumberField(value: "20")
        reviewCountField = createNumberField(value: "50")
        
        card.addFormRow(items: [
            (label: "每日新学单词数", control: newWordsField),
            (label: "每日复习单词数", control: reviewCountField)
        ])
        
        return card
    }
    
    private func createStatusBarCard() -> LLSettingsCardView {
        let card = LLSettingsCardView(title: "状态栏设置", icon: "🔔")
        
        statusBarIntervalField = createNumberField(value: "30")
        
        statusBarDisplayPopup = NSPopUpButton()
        statusBarDisplayPopup.target = self
        statusBarDisplayPopup.action = #selector(saveSettings)
        statusBarDisplayPopup.addItems(withTitles: ["仅单词", "单词+音标", "单词+简易释义"])
        
        statusBarPhoneticCheck = NSButton(checkboxWithTitle: "显示音标", target: self, action: #selector(saveSettings))
        
        statusBarMaxLengthField = createNumberField(value: "20")
        
        // 新增：状态栏是否显示内容
        statusBarShowContentCheck = NSButton(checkboxWithTitle: "状态栏显示内容", target: self, action: #selector(saveSettings))
        
        // 新增：状态栏显示内容细分控制
        statusBarShowWordCheck = NSButton(checkboxWithTitle: "显示单词", target: self, action: #selector(saveSettings))
        statusBarShowPhoneticSymbolCheck = NSButton(checkboxWithTitle: "显示音标", target: self, action: #selector(saveSettings))
        statusBarShowMeaningCheck = NSButton(checkboxWithTitle: "显示释义", target: self, action: #selector(saveSettings))
        statusBarAutoScrollCheck = NSButton(checkboxWithTitle: "释义不够时自动滚动", target: self, action: #selector(saveSettings))
        
        // 创建显示内容选项的水平布局
        let displayOptionsStack = NSStackView(views: [
            statusBarShowWordCheck,
            statusBarShowPhoneticSymbolCheck,
            statusBarShowMeaningCheck
        ])
        displayOptionsStack.orientation = .horizontal
        displayOptionsStack.spacing = 16
        displayOptionsStack.distribution = .fillEqually
        
        // 新增：状态栏内容宽度滑块
        statusBarContentWidthSlider = NSSlider(value: 150, minValue: 135, maxValue: 300, target: self, action: #selector(onStatusBarWidthChanged))
        statusBarContentWidthSlider.isContinuous = true
        
        statusBarContentWidthLabel = NSTextField(labelWithString: "150")
        statusBarContentWidthLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        statusBarContentWidthLabel.textColor = NSColor(white: 0.4, alpha: 1.0)
        statusBarContentWidthLabel.alignment = .right
        statusBarContentWidthLabel.snp.makeConstraints { make in
            make.width.equalTo(40)
        }
        
        let widthSliderStack = NSStackView(views: [statusBarContentWidthSlider, statusBarContentWidthLabel])
        widthSliderStack.orientation = .horizontal
        widthSliderStack.spacing = 8
        widthSliderStack.distribution = .fill
        statusBarContentWidthSlider.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(200)
        }
        
        // 新增：是否显示反馈按钮
        showFeedbackButtonsCheck = NSButton(checkboxWithTitle: "显示反馈按钮", target: self, action: #selector(saveSettings))
        
        card.addFormItem(label: "单词自动切换时间（秒）", control: statusBarIntervalField)
        card.addFormItem(label: "显示内容", control: displayOptionsStack)
        card.addFormItem(label: "滚动设置", control: statusBarAutoScrollCheck)
        card.addFormItem(label: "状态栏显示宽度", control: widthSliderStack)
        card.addFormItem(label: "按钮控制", control: showFeedbackButtonsCheck)
        
        return card
    }
    
    private func createReviewCard() -> LLSettingsCardView {
        let card = LLSettingsCardView(title: "复习设置", icon: "🔄")
        
        reviewModePopup = NSPopUpButton()
        reviewModePopup.target = self
        reviewModePopup.action = #selector(saveSettings)
        reviewModePopup.addItems(withTitles: ["极简模式（当天/隔天/3天）", "艾宾浩斯曲线（推荐）"])
        
        wrongWordRetryField = createNumberField(value: "3")
        
        card.addFormItem(label: "复习间隔规则", control: reviewModePopup)
        card.addFormItem(label: "答错单词重学次数", control: wrongWordRetryField)
        
        return card
    }
    
    private func createPronunciationCard() -> LLSettingsCardView {
        let card = LLSettingsCardView(title: "发音设置", icon: "🔊")
        
        pronunciationCheck = NSButton(checkboxWithTitle: "启用发音", target: self, action: #selector(saveSettings))
        
        pronunciationProviderPopup = NSPopUpButton()
        pronunciationProviderPopup.target = self
        pronunciationProviderPopup.action = #selector(saveSettings)
        for provider in LLPronunciationProvider.allCases {
            pronunciationProviderPopup.addItem(withTitle: provider.displayName)
        }
        
        pronunciationAccentPopup = NSPopUpButton()
        pronunciationAccentPopup.target = self
        pronunciationAccentPopup.action = #selector(saveSettings)
        for accent in LLPronunciationAccent.allCases {
            pronunciationAccentPopup.addItem(withTitle: "\(accent.flag) \(accent.displayName)")
        }
        
        pronunciationRateSlider = NSSlider(value: 0.4, minValue: 0.1, maxValue: 1.0, target: self, action: #selector(saveSettings))
        pronunciationRateSlider.isContinuous = true
        
        card.addFormItem(label: "发音开关", control: pronunciationCheck)
        card.addFormRow(items: [
            (label: "发音提供者", control: pronunciationProviderPopup),
            (label: "发音口音", control: pronunciationAccentPopup)
        ])
        card.addFormItem(label: "语速调节", control: pronunciationRateSlider)
        
        return card
    }
    
    private func createFloatingPanelCard() -> LLSettingsCardView {
        let card = LLSettingsCardView(title: "浮窗设置", icon: "🪟")
        
        panelAlphaSlider = NSSlider(value: 0.55, minValue: 0.2, maxValue: 1, target: self, action: #selector(saveSettings))
        panelAlphaSlider.isContinuous = true
        
        panelWidthField = createNumberField(value: "400")
        panelHeightField = createNumberField(value: "200")
        
        typingPracticeEnabledCheck = NSButton(checkboxWithTitle: "启用打字练习", target: self, action: #selector(saveSettings))
        typingPracticeShowMeaningCheck = NSButton(checkboxWithTitle: "打字练习显示释义", target: self, action: #selector(saveSettings))
        
        let typingStack = NSStackView(views: [typingPracticeEnabledCheck, typingPracticeShowMeaningCheck])
        typingStack.orientation = .horizontal
        typingStack.spacing = 16
        
        typingInputStylePopup = NSPopUpButton()
        typingInputStylePopup.target = self
        typingInputStylePopup.action = #selector(saveSettings)
        for style in LLTypingInputStyle.allCases {
            typingInputStylePopup.addItem(withTitle: style.displayName)
        }
        
        autoShowAnswerPopup = NSPopUpButton()
        autoShowAnswerPopup.target = self
        autoShowAnswerPopup.action = #selector(saveSettings)
        autoShowAnswerPopup.addItems(withTitles: LLAutoShowAnswerOption.allDisplayNames)
        
        addToWrongBookPopup = NSPopUpButton()
        addToWrongBookPopup.target = self
        addToWrongBookPopup.action = #selector(saveSettings)
        addToWrongBookPopup.addItems(withTitles: LLAddToWrongBookOption.allDisplayNames)
        
        card.addFormItem(label: "浮窗透明度", control: panelAlphaSlider)
        card.addFormRow(items: [
            (label: "浮窗宽度", control: panelWidthField),
            (label: "浮窗高度", control: panelHeightField)
        ])
        card.addFormItem(label: "打字练习", control: typingStack)
        card.addFormItem(label: "答题输入框样式", control: typingInputStylePopup)
        card.addFormRow(items: [
            (label: "自动显示答案", control: autoShowAnswerPopup),
            (label: "记录到错题本", control: addToWrongBookPopup)
        ])
        
        return card
    }
    
    private func createShortcutCard() -> LLSettingsCardView {
        let card = LLSettingsCardView(title: "快捷键设置", icon: "⌨️")
        
        shortcutPlaceholderLabel = NSTextField(labelWithString: "快捷键功能开发中，敬请期待...")
        shortcutPlaceholderLabel.font = NSFont.systemFont(ofSize: 13)
        shortcutPlaceholderLabel.textColor = NSColor(white: 0.5, alpha: 1.0)
        shortcutPlaceholderLabel.alignment = .center
        
        card.addFormItem(label: "", control: shortcutPlaceholderLabel)
        
        // TODO: 未来可以在这里添加快捷键设置项，例如：
        // - 显示/隐藏主窗口
        // - 切换到下一个单词
        // - 标记为已掌握
        // - 开始/暂停学习
        // - 打开浮窗
        // 等等...
        
        return card
    }
    
    private func createOtherCard() -> LLSettingsCardView {
        let card = LLSettingsCardView(title: "其他设置", icon: "⚙️")
        
        launchAtLoginCheck = NSButton(checkboxWithTitle: "开机自动启动", target: self, action: #selector(toggleLaunchAtLogin))
        
        card.addFormItem(label: "启动设置", control: launchAtLoginCheck)
        
        return card
    }
    
    // MARK: - Helper Methods
    
    private func createNumberField(value: String) -> NSTextField {
        let field = NSTextField(string: value)
        field.font = NSFont.systemFont(ofSize: 14)
        field.placeholderString = "请输入数字"
        field.target = self
        field.action = #selector(saveSettings)
        return field
    }

    
    // MARK: - Load & Save Settings
    
    private func loadSettings() {
        let s = LLSettingsStore.shared.settings
        
        // 学习目标
        newWordsField.stringValue = "\(s.newWordsPerDay)"
        reviewCountField.stringValue = "\(s.reviewCountPerDay)"
        
        // 状态栏设置
        statusBarIntervalField.stringValue = "30"
        statusBarDisplayPopup.selectItem(at: s.statusBarShowPhonetic ? 1 : 0)
        statusBarPhoneticCheck.state = s.statusBarShowPhonetic ? .on : .off
        statusBarMaxLengthField.stringValue = "\(s.statusBarMaxLength)"
        statusBarShowContentCheck.state = s.statusBarShowContent ? .on : .off
        statusBarContentWidthSlider.integerValue = s.statusBarContentWidth
        statusBarContentWidthLabel.stringValue = "\(s.statusBarContentWidth)"
        showFeedbackButtonsCheck.state = s.showFeedbackButtons ? .on : .off
        
        // 新增：状态栏显示内容细分控制
        statusBarShowWordCheck.state = s.statusBarShowWord ? .on : .off
        statusBarShowPhoneticSymbolCheck.state = s.statusBarShowPhoneticSymbol ? .on : .off
        statusBarShowMeaningCheck.state = s.statusBarShowMeaning ? .on : .off
        statusBarAutoScrollCheck.state = s.statusBarAutoScroll ? .on : .off
        
        // 复习设置
        reviewModePopup.selectItem(at: 1)
        wrongWordRetryField.stringValue = "3"
        
        // 发音设置
        pronunciationCheck.state = s.pronunciationEnabled ? .on : .off
        if let index = LLPronunciationProvider.allCases.firstIndex(of: s.pronunciationProvider) {
            pronunciationProviderPopup.selectItem(at: index)
        }
        if let index = LLPronunciationAccent.allCases.firstIndex(of: s.pronunciationAccent) {
            pronunciationAccentPopup.selectItem(at: index)
        }
        pronunciationRateSlider.floatValue = s.pronunciationRate
        
        // 其他设置
        panelAlphaSlider.doubleValue = s.floatingPanelAlpha
        panelWidthField.stringValue = "\(Int(s.floatingPanelWidth))"
        panelHeightField.stringValue = "\(Int(s.floatingPanelHeight))"
        typingPracticeEnabledCheck.state = s.typingPracticeEnabled ? .on : .off
        typingPracticeShowMeaningCheck.state = s.typingPracticeShowMeaning ? .on : .off
        if let index = LLTypingInputStyle.allCases.firstIndex(of: s.typingInputStyle) {
            typingInputStylePopup.selectItem(at: index)
        }
        // 自动显示答案：使用枚举来映射
        let autoShowOption = LLAutoShowAnswerOption.from(errorCount: s.autoShowAnswerAfterErrors)
        if let index = LLAutoShowAnswerOption.allCases.firstIndex(of: autoShowOption) {
            autoShowAnswerPopup.selectItem(at: index)
        }
        
        // 记录到错题本：使用枚举来映射
        let wrongBookOption = LLAddToWrongBookOption.from(errorCount: s.addToWrongBookAfterErrors)
        if let index = LLAddToWrongBookOption.allCases.firstIndex(of: wrongBookOption) {
            addToWrongBookPopup.selectItem(at: index)
        }
        launchAtLoginCheck.state = LaunchAtLogin.isEnabled ? .on : .off
    }

    @objc private func saveSettings() {
        var s = LLSettingsStore.shared.settings
        
        // 学习目标
        s.newWordsPerDay = Int(newWordsField.stringValue) ?? 20
        s.reviewCountPerDay = Int(reviewCountField.stringValue) ?? 50
        
        // 状态栏设置
        s.statusBarShowPhonetic = statusBarPhoneticCheck.state == .on
        s.statusBarMaxLength = Int(statusBarMaxLengthField.stringValue) ?? 20
        s.statusBarShowContent = statusBarShowContentCheck.state == .on
        s.statusBarContentWidth = statusBarContentWidthSlider.integerValue
        s.showFeedbackButtons = showFeedbackButtonsCheck.state == .on
        
        // 新增：状态栏显示内容细分控制
        s.statusBarShowWord = statusBarShowWordCheck.state == .on
        s.statusBarShowPhoneticSymbol = statusBarShowPhoneticSymbolCheck.state == .on
        s.statusBarShowMeaning = statusBarShowMeaningCheck.state == .on
        s.statusBarAutoScroll = statusBarAutoScrollCheck.state == .on
        
        // 发音设置
        s.pronunciationEnabled = pronunciationCheck.state == .on
        let providerIndex = pronunciationProviderPopup.indexOfSelectedItem
        if providerIndex >= 0 && providerIndex < LLPronunciationProvider.allCases.count {
            s.pronunciationProvider = LLPronunciationProvider.allCases[providerIndex]
        }
        let accentIndex = pronunciationAccentPopup.indexOfSelectedItem
        if accentIndex >= 0 && accentIndex < LLPronunciationAccent.allCases.count {
            s.pronunciationAccent = LLPronunciationAccent.allCases[accentIndex]
        }
        s.pronunciationRate = pronunciationRateSlider.floatValue
        
        // 其他设置
        s.floatingPanelAlpha = panelAlphaSlider.doubleValue
        s.floatingPanelWidth = CGFloat(Int(panelWidthField.stringValue) ?? 400)
        s.floatingPanelHeight = CGFloat(Int(panelHeightField.stringValue) ?? 200)
        s.typingPracticeEnabled = typingPracticeEnabledCheck.state == .on
        s.typingPracticeShowMeaning = typingPracticeShowMeaningCheck.state == .on
        
        // 打字练习输入框样式
        let inputStyleIndex = typingInputStylePopup.indexOfSelectedItem
        if inputStyleIndex >= 0 && inputStyleIndex < LLTypingInputStyle.allCases.count {
            s.typingInputStyle = LLTypingInputStyle.allCases[inputStyleIndex]
        }
        
        // 自动显示答案
        let autoShowIndex = autoShowAnswerPopup.indexOfSelectedItem
        if autoShowIndex >= 0 && autoShowIndex < LLAutoShowAnswerOption.allCases.count {
            s.autoShowAnswerAfterErrors = LLAutoShowAnswerOption.allCases[autoShowIndex].rawValue
        }
        
        // 记录到错题本
        let wrongBookIndex = addToWrongBookPopup.indexOfSelectedItem
        if wrongBookIndex >= 0 && wrongBookIndex < LLAddToWrongBookOption.allCases.count {
            s.addToWrongBookAfterErrors = LLAddToWrongBookOption.allCases[wrongBookIndex].rawValue
        }
        
        LLSettingsStore.shared.settings = s
        
        // 发送通知刷新状态栏
        NotificationCenter.default.post(name: .learnLanguageRefreshStatus, object: nil)
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.isEnabled = launchAtLoginCheck.state == .on
        var s = LLSettingsStore.shared.settings
        s.launchAtLogin = LaunchAtLogin.isEnabled
        LLSettingsStore.shared.settings = s
        print("开机自启动已\(LaunchAtLogin.isEnabled ? "开启" : "关闭")")
    }
    
    @objc private func onStatusBarWidthChanged() {
        let width = statusBarContentWidthSlider.integerValue
        statusBarContentWidthLabel.stringValue = "\(width)"
        saveSettings()
    }
}
