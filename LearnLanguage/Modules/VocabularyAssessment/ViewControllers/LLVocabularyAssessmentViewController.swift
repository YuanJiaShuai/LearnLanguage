//
//  LLVocabularyAssessmentViewController.swift
//  LearnLanguage
//
//  学习实验室 - 词汇量评估首页
//

import AppKit
import SnapKit

final class LLVocabularyAssessmentViewController: NSViewController {
    private struct WordBank: Decodable { let entries: [Entry] }
    private struct Entry: Decodable { let id: String; let word: String; let band: String; let difficulty: Int; let meaning: String }
    private struct Question { let entry: Entry; let options: [String]; let answer: Int }

    private let onBack: () -> Void

    private var bank: WordBank?
    private var usedIDs = Set<String>()
    private var theta: Double = 0
    private var questions: [Question] = []
    private var results: [(band: String, correct: Bool)] = []
    private var recent: [Bool] = []
    private var selectedOption: Int?

    private let minQuestions = 10
    private let maxQuestions = 20
    private let recentWindow = 5
    private let maxWrongInWindow = 4

    private let card = NSView()
    private let statusLabel = NSTextField(labelWithString: "")
    private let wordLabel = NSTextField(labelWithString: "")
    private let feedbackLabel = NSTextField(labelWithString: "")
    private let startButton = NSButton(title: "开始测试", target: nil, action: nil)
    private let nextButton = NSButton(title: "下一题", target: nil, action: nil)
    private var optionButtons: [NSButton] = []

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
        loadWordBank()
        renderIntro()
    }

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor

        let backButton = NSButton(title: "返回", target: self, action: #selector(onBackTapped))
        backButton.isBordered = false
        backButton.font = .systemFont(ofSize: 14, weight: .semibold)
        backButton.image = NSImage(systemSymbolName: "chevron.left", accessibilityDescription: nil)
        backButton.imagePosition = .imageLeading
        backButton.contentTintColor = .systemTeal
        view.addSubview(backButton)
        backButton.snp.makeConstraints { $0.top.equalToSuperview().offset(28); $0.leading.equalToSuperview().offset(28) }

        let titleLabel = NSTextField(labelWithString: "词汇量评估")
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.top.equalTo(backButton.snp.bottom).offset(28); $0.leading.equalToSuperview().offset(40) }

        let subtitleLabel = NSTextField(labelWithString: "Vocabulary Assessment · Swift IRT")
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        subtitleLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.62)
        view.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { $0.top.equalTo(titleLabel.snp.bottom).offset(10); $0.leading.equalToSuperview().offset(40) }

        card.wantsLayer = true
        card.layer?.cornerRadius = 20
        card.layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
        card.layer?.borderWidth = 1
        card.layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.4).cgColor
        view.addSubview(card)
        card.snp.makeConstraints { $0.top.equalTo(subtitleLabel.snp.bottom).offset(24); $0.leading.trailing.equalToSuperview().inset(40); $0.bottom.equalToSuperview().offset(-40) }

        statusLabel.font = .systemFont(ofSize: 14, weight: .medium)
        statusLabel.maximumNumberOfLines = 0
        statusLabel.lineBreakMode = .byWordWrapping
        card.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(28) }

        wordLabel.font = .systemFont(ofSize: 32, weight: .bold)
        wordLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        card.addSubview(wordLabel)
        wordLabel.snp.makeConstraints { $0.top.equalTo(statusLabel.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(28) }

        var prev: NSView = wordLabel
        for i in 0..<4 {
            let btn = NSButton(title: "", target: self, action: #selector(onOptionTapped(_:)))
            btn.tag = i
            btn.isBordered = true
            btn.bezelStyle = .rounded
            btn.font = .systemFont(ofSize: 14, weight: .medium)
            btn.contentTintColor = LLAppearanceManager.shared.colors.primaryText
            optionButtons.append(btn)
            card.addSubview(btn)
            btn.snp.makeConstraints {
                $0.top.equalTo(prev.snp.bottom).offset(12)
                $0.leading.trailing.equalToSuperview().inset(28)
                $0.height.equalTo(40)
            }
            prev = btn
        }

        feedbackLabel.font = .systemFont(ofSize: 13, weight: .medium)
        feedbackLabel.maximumNumberOfLines = 0
        feedbackLabel.lineBreakMode = .byWordWrapping
        card.addSubview(feedbackLabel)
        feedbackLabel.snp.makeConstraints { $0.top.equalTo(prev.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(28) }

        startButton.target = self
        startButton.action = #selector(onStartTapped)
        card.addSubview(startButton)
        startButton.snp.makeConstraints { $0.leading.equalToSuperview().offset(28); $0.bottom.equalToSuperview().offset(-28); $0.height.equalTo(36) }

        nextButton.target = self
        nextButton.action = #selector(onNextTapped)
        card.addSubview(nextButton)
        nextButton.snp.makeConstraints { $0.leading.equalTo(startButton.snp.trailing).offset(12); $0.centerY.equalTo(startButton) }
    }

    private func loadWordBank() {
        let u = Bundle.main.url(forResource: "assessment_word_bank_en_v1", withExtension: "json", subdirectory: "Assessment")
            ?? Bundle.main.url(forResource: "assessment_word_bank_en_v1", withExtension: "json")
        guard let url = u, let data = try? Data(contentsOf: url), let decoded = try? JSONDecoder().decode(WordBank.self, from: data) else {
            statusLabel.stringValue = "词库加载失败，请检查 assessment_word_bank_en_v1.json"
            return
        }
        bank = decoded
        startButton.isEnabled = true
    }

    private func renderIntro() {
        wordLabel.isHidden = true
        optionButtons.forEach { $0.isHidden = true }
        feedbackLabel.isHidden = true
        nextButton.isHidden = true
        startButton.isHidden = false

        statusLabel.stringValue = "将使用 Swift 原生 IRT 风格逻辑进行评估。\n词库数量：\(bank?.entries.count ?? 0)\n点击“开始测试”后按能力值动态出题。"
    }

    private func startTest() {
        usedIDs.removeAll(); questions.removeAll(); results.removeAll(); recent.removeAll()
        theta = 0; selectedOption = nil
        nextRound()
    }

    private func nextRound() {
        if shouldStop() { renderResult(); return }
        guard let q = makeQuestion() else { renderResult(); return }
        questions.append(q)
        renderQuestion(q)
    }

    private func makeQuestion() -> Question? {
        guard let all = bank?.entries, !all.isEmpty else { return nil }
        let target = Int(round(max(1, min(7, theta))))
        func avail(_ d: Int) -> [Entry] { all.filter { $0.difficulty == d && !usedIDs.contains($0.id) } }

        var c = avail(target)
        if c.isEmpty {
            for s in 1...3 {
                c = avail(max(1, target - s)); if !c.isEmpty { break }
                c = avail(min(7, target + s)); if !c.isEmpty { break }
            }
        }
        if c.isEmpty { usedIDs.removeAll(); c = avail(target) }
        guard let e = c.randomElement() else { return nil }
        usedIDs.insert(e.id)

        var pool = all.filter { $0.id != e.id && $0.meaning != e.meaning && $0.difficulty == e.difficulty }
        if pool.count < 3 { pool = all.filter { $0.id != e.id && $0.meaning != e.meaning } }
        let ds = Array(Set(pool.shuffled().prefix(12).map(\ .meaning))).prefix(3)
        guard ds.count == 3 else { return nil }

        var opts = Array(ds)
        opts.append(e.meaning)
        opts.shuffle()
        guard let ans = opts.firstIndex(of: e.meaning) else { return nil }
        return Question(entry: e, options: opts, answer: ans)
    }

    private func renderQuestion(_ q: Question) {
        selectedOption = nil
        startButton.isHidden = true
        nextButton.isHidden = false
        wordLabel.isHidden = false
        optionButtons.forEach { $0.isHidden = false; $0.isEnabled = true }
        feedbackLabel.isHidden = false

        statusLabel.stringValue = "第 \(questions.count) 题  ·  能力值 θ \(String(format: "%.2f", theta))"
        wordLabel.stringValue = q.entry.word
        for (i, b) in optionButtons.enumerated() { b.title = q.options[i] }
        feedbackLabel.stringValue = "请选择最接近的中文释义"
        feedbackLabel.textColor = LLAppearanceManager.shared.colors.secondaryText
        nextButton.title = "请先作答"
        nextButton.isEnabled = false
    }

    private func submit(_ selected: Int) {
        guard selectedOption == nil, let q = questions.last else { return }
        selectedOption = selected
        let ok = selected == q.answer

        results.append((q.entry.band, ok))
        recent.append(ok); if recent.count > recentWindow { recent.removeFirst() }
        updateTheta(diff: Double(q.entry.difficulty), ok: ok)

        for (i, b) in optionButtons.enumerated() {
            b.isEnabled = false
            if i == q.answer { b.contentTintColor = .systemGreen }
            else if i == selected { b.contentTintColor = .systemRed }
            else { b.contentTintColor = LLAppearanceManager.shared.colors.secondaryText }
        }

        feedbackLabel.textColor = ok ? .systemGreen : .systemRed
        feedbackLabel.stringValue = ok ? "回答正确：\(q.entry.word) = \(q.entry.meaning)" : "回答错误：正确答案是“\(q.entry.meaning)”"
        nextButton.title = shouldStop() ? "查看结果" : "下一题"
        nextButton.isEnabled = true
    }

    private func updateTheta(diff b: Double, ok: Bool) {
        let a = 1.2, lr = 0.05, penalty = 0.6
        let ex = max(-20.0, min(20.0, a * (theta - b)))
        let p = 1.0 / (1.0 + exp(-ex))
        let info = max(1e-8, p * (1 - p))
        let delta = lr * (1 - p) / info
        theta += ok ? delta : -delta * penalty
        theta = max(0.0, min(7.5, theta))
    }

    private func shouldStop() -> Bool {
        let n = results.count
        if n >= maxQuestions { return true }
        if n >= max(minQuestions, recentWindow), recent.filter({ !$0 }).count >= maxWrongInWindow { return true }
        return false
    }

    private func renderResult() {
        wordLabel.isHidden = true
        optionButtons.forEach { $0.isHidden = true }
        nextButton.isHidden = true
        startButton.isHidden = true
        feedbackLabel.isHidden = false

        let c = results.filter { $0.correct }.count
        let t = max(results.count, 1)
        let acc = Double(c) / Double(t)
        statusLabel.stringValue = "测试完成"
        feedbackLabel.textColor = LLAppearanceManager.shared.colors.primaryText
        feedbackLabel.stringValue = String(format: "得分：%d/%d\n能力值 θ=%.2f\n正确率 %.0f%%\n估算词汇量约 %d", c, results.count, theta, acc * 100, estimateVocab(theta))
    }

    private func estimateVocab(_ a: Double) -> Int {
        let m = [1: 200, 2: 500, 3: 1200, 4: 2800, 5: 3500, 6: 4500, 7: 6000]
        let l = Int(floor(a))
        let f = a - Double(l)
        if l >= 7 { return m[7] ?? 6000 }
        if l < 1 { return Int(round(f * Double(m[1] ?? 200))) }
        let c = m[l] ?? 200
        let n = m[min(7, l + 1)] ?? 6000
        return Int(round(Double(c) + f * Double(n - c)))
    }

    @objc private func onBackTapped() { onBack() }
    @objc private func onStartTapped() { startTest() }
    @objc private func onOptionTapped(_ sender: NSButton) { submit(sender.tag) }
    @objc private func onNextTapped() { guard selectedOption != nil else { return }; nextRound() }
}

