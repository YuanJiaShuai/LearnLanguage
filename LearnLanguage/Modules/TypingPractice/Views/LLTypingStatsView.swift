//
//  LLTypingStatsView.swift
//  LearnLanguage
//
//  打字统计视图 - 显示速度、准确率等信息

import AppKit
import SnapKit

/// 打字统计视图
class LLTypingStatsView: NSView {
    
    // MARK: - Properties
    
    private let accuracyLabel = NSTextField()
    private let speedLabel = NSTextField()
    private let timeLabel = NSTextField()
    
    private let stackView = NSStackView()
    
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        wantsLayer = true
        
        // 配置标签
        [accuracyLabel, speedLabel, timeLabel].forEach { label in
            label.isEditable = false
            label.isBordered = false
            label.backgroundColor = .clear
            label.alignment = .center
            label.font = NSFont.systemFont(ofSize: 14)
            label.textColor = .secondaryLabelColor
        }
        
        // 配置 StackView
        stackView.orientation = .horizontal
        stackView.spacing = 20
        stackView.alignment = .centerY
        stackView.distribution = .fillEqually
        
        stackView.addArrangedSubview(accuracyLabel)
        stackView.addArrangedSubview(speedLabel)
        stackView.addArrangedSubview(timeLabel)
        
        addSubview(stackView)
        
        // 布局
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        reset()
    }
    
    // MARK: - Public Methods
    
    /// 更新统计数据
    /// - Parameters:
    ///   - accuracy: 准确率 (0-100)
    ///   - speed: 速度 (字符/分钟)
    ///   - time: 用时 (秒)
    func updateStats(accuracy: Int, speed: Int, time: Int) {
        accuracyLabel.stringValue = "准确率: \(accuracy)%"
        speedLabel.stringValue = "速度: \(speed) CPM"
        timeLabel.stringValue = "用时: \(time)s"
    }
    
    /// 重置统计数据
    func reset() {
        accuracyLabel.stringValue = "准确率: 0%"
        speedLabel.stringValue = "速度: 0 CPM"
        timeLabel.stringValue = "用时: 0s"
    }
}

