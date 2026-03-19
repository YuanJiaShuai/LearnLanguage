//
//  LLStatContentView.swift
//  LearnLanguage
//
//  学习统计内容视图（词库卡 + 3统计卡 + 趋势图）
//  全部 frame 布局

import AppKit

final class LLStatContentView: NSView {
    
    // MARK: - Layout Constants
    private let kPadding: CGFloat = 16
    private let kSpacing: CGFloat = 12
    private let kCurrentListHeight: CGFloat = 290
    private let kStatsRowHeight: CGFloat = 110
    private let kTrendHeight: CGFloat = 180
    
    // MARK: - UI Components
    
    private let scrollView: NSScrollView = {
        let sv = NSScrollView()
        sv.hasVerticalScroller = true
        sv.hasHorizontalScroller = false
        sv.autohidesScrollers = true
        sv.borderType = .noBorder
        sv.drawsBackground = false
        return sv
    }()
    
    private let documentView = _StatFlippedView()
    
    private var currentListCard: LLCurrentListCardView!
    private var totalWordsCard: LLStatCardView!
    private var progressCard: LLProgressCardView!
    private var streakCard: LLStatCardView!
    private var trendCard: LLTrendCardView!
    private var statsRowView: NSView!
    
    // MARK: - Callbacks
    
    var onChangeWordListClicked: (() -> Void)?
    
    // MARK: - Lifecycle
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        currentListCard = LLCurrentListCardView()
        currentListCard.onChangeButtonClicked = { [weak self] in
            self?.onChangeWordListClicked?()
        }
        
        totalWordsCard = LLStatCardView(icon: "📚", description: NSLocalizedString("Total Words Learned", comment: ""))
        progressCard = LLProgressCardView()
        streakCard = LLStatCardView(icon: "🔥", description: NSLocalizedString("Streak Days", comment: ""))
        
        statsRowView = NSView()
        statsRowView.addSubview(totalWordsCard)
        statsRowView.addSubview(progressCard)
        statsRowView.addSubview(streakCard)
        
        trendCard = LLTrendCardView()
        
        documentView.addSubview(currentListCard)
        documentView.addSubview(statsRowView)
        documentView.addSubview(trendCard)
        
        scrollView.documentView = documentView
        addSubview(scrollView)
    }
    
    // MARK: - Layout
    
    override func layout() {
        super.layout()
        let w = bounds.width
        guard w > 0 else { return }
        
        scrollView.frame = bounds
        
        let innerW = w - kPadding * 2
        var y: CGFloat = kPadding
        
        // 1. 当前词库卡片
        currentListCard.frame = NSRect(x: kPadding, y: y, width: innerW, height: kCurrentListHeight)
        y += kCurrentListHeight + kSpacing
        
        // 2. 统计行三等分
        statsRowView.frame = NSRect(x: kPadding, y: y, width: innerW, height: kStatsRowHeight)
        let statW = (innerW - kSpacing * 2) / 3
        totalWordsCard.frame = NSRect(x: 0, y: 0, width: statW, height: kStatsRowHeight)
        progressCard.frame   = NSRect(x: statW + kSpacing, y: 0, width: statW, height: kStatsRowHeight)
        streakCard.frame     = NSRect(x: (statW + kSpacing) * 2, y: 0, width: statW, height: kStatsRowHeight)
        y += kStatsRowHeight + kSpacing
        
        // 3. 趋势图
        trendCard.frame = NSRect(x: kPadding, y: y, width: innerW, height: kTrendHeight)
        y += kTrendHeight + kPadding
        
        documentView.frame = NSRect(x: 0, y: 0, width: w, height: y)
        
        currentListCard.needsLayout = true
        statsRowView.needsLayout = true
        totalWordsCard.needsLayout = true
        progressCard.needsLayout = true
        streakCard.needsLayout = true
        trendCard.needsLayout = true
    }
    
    // MARK: - Public Methods
    
    func updateStatistics(totalWords: Int, days: Int, todayCount: Int, todayGoal: Int) {
        totalWordsCard?.updateNumber("\(totalWords)")
        streakCard?.updateNumber("\(days)")
        progressCard?.updateProgress(current: todayCount, total: todayGoal)
    }
}

private final class _StatFlippedView: NSView {
    override var isFlipped: Bool { true }
}
