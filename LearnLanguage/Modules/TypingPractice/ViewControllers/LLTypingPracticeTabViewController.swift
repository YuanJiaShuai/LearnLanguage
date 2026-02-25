//
//  LLTypingPracticeTabViewController.swift
//  LearnLanguage
//
//  打字练习标签页控制器

import AppKit
import SnapKit

class LLTypingPracticeTabViewController: NSViewController {
    
    // MARK: - Properties
    
    private var typingViewController: LLTypingPracticeViewController?
    private let messageLabel = NSTextField()
    
    // MARK: - Lifecycle
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTypingPractice()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // 添加标题和说明
        let titleLabel = NSTextField(labelWithString: "打字练习")
        titleLabel.isEditable = false
        titleLabel.isBordered = false
        titleLabel.backgroundColor = .clear
        titleLabel.font = NSFont.boldSystemFont(ofSize: 20)
        
        let instructionLabel = NSTextField(labelWithString: "通过打字练习加深单词记忆")
        instructionLabel.isEditable = false
        instructionLabel.isBordered = false
        instructionLabel.backgroundColor = .clear
        instructionLabel.font = NSFont.systemFont(ofSize: 14)
        instructionLabel.textColor = .secondaryLabelColor
        
        // 消息标签（用于显示错误或提示信息）
        messageLabel.isEditable = false
        messageLabel.isBordered = false
        messageLabel.backgroundColor = .clear
        messageLabel.alignment = .center
        messageLabel.font = NSFont.systemFont(ofSize: 16)
        messageLabel.textColor = .secondaryLabelColor
        messageLabel.stringValue = ""
        messageLabel.isHidden = true
        
        view.addSubview(titleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(messageLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.centerX.equalToSuperview()
        }
        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        messageLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().offset(-40)
        }
    }
    
    private func setupTypingPractice() {
        typingViewController = LLTypingPracticeViewController()
        guard let typingVC = typingViewController else { return }
        
        addChild(typingVC)
        
        view.addSubview(typingVC.view)
        typingVC.view.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(80)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        // 设置回调
        typingVC.onNextWord = { [weak self] in
            self?.loadNextWord()
        }
        
        typingVC.onWordCompleted = { [weak self] feedback in
            LLTypingPracticeManager.shared.recordResult(feedback: feedback)
            self?.loadNextWord()
        }
        
        // 加载第一个单词
        loadNextWord()
    }
    
    // MARK: - Private Methods
    
    private func loadNextWord() {
        // 检查打字练习是否启用
        let settings = LLSettingsStore.shared.settings
        
        // 获取当前词库
        guard let currentListId = LLSettingsStore.shared.currentListId else {
            DispatchQueue.main.async { [weak self] in
                self?.showNoListAlert()
            }
            return
        }
        
        // 开始练习
        LLTypingPracticeManager.shared.startPractice(listId: currentListId)
        
        // 优先获取状态栏当前显示的单词，如果没有则获取下一个
        let wordToPractice = LLTypingPracticeManager.shared.getCurrentStatusBarWord() 
            ?? LLTypingPracticeManager.shared.getNextWord()
        
        if let word = wordToPractice {
            hideMessage()
            typingViewController?.startPractice(with: word)
        } else {
            showMessage("没有更多单词了！\n已完成本次练习")
        }
    }
    
    private func showMessage(_ message: String) {
        messageLabel.stringValue = message
        messageLabel.isHidden = false
        typingViewController?.view.isHidden = true
    }
    
    private func hideMessage() {
        messageLabel.isHidden = true
        typingViewController?.view.isHidden = false
    }
    
    private func showNoListAlert() {
        let alert = NSAlert()
        alert.messageText = "请选择一个词库"
        alert.informativeText = "在开始打字练习之前，请先选择一个词库。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
        
        showMessage("请先选择一个词库")
    }
}
