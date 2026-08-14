//
//  LLStatContentView.swift
//  LearnLanguage
//
//  学习统计内容视图（词库卡 + 3统计卡 + 趋势图）

import AppKit
import SnapKit

final class LLStatContentView: NSView {
    
    // MARK: - Layout Constants
    private let kPadding: CGFloat = 16
    private let kSpacing: CGFloat = 12
    private let kCurrentListHeight: CGFloat = 232
    private let kStatsRowHeight: CGFloat = 104
    private let kCompactStatsRowHeight: CGFloat = 336
    private let kTrendHeight: CGFloat = 210
    
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
    private var isUsingStackedStats = false
    
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
        
        totalWordsCard = LLStatCardView(icon: "text.book.closed", description: NSLocalizedString("Total Words Learned", comment: ""), detail: NSLocalizedString("words", comment: ""))
        progressCard = LLProgressCardView()
        streakCard = LLStatCardView(icon: "flame", description: NSLocalizedString("Streak Days", comment: ""), detail: NSLocalizedString("days", comment: ""))
        
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

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        documentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        currentListCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(kPadding)
            make.leading.trailing.equalToSuperview().inset(kPadding)
            make.height.equalTo(kCurrentListHeight)
        }

        statsRowView.snp.makeConstraints { make in
            make.top.equalTo(currentListCard.snp.bottom).offset(kSpacing)
            make.leading.trailing.equalToSuperview().inset(kPadding)
            make.height.equalTo(kStatsRowHeight)
        }

        trendCard.snp.makeConstraints { make in
            make.top.equalTo(statsRowView.snp.bottom).offset(kSpacing)
            make.leading.trailing.equalToSuperview().inset(kPadding)
            make.height.equalTo(kTrendHeight)
            make.bottom.equalToSuperview().inset(kPadding)
        }

        updateStatsLayout(stacked: false)
    }
    
    // MARK: - Layout
    
    override func layout() {
        super.layout()
        let shouldStack = bounds.width - kPadding * 2 < 680
        if shouldStack != isUsingStackedStats {
            updateStatsLayout(stacked: shouldStack)
        }
    }

    private func updateStatsLayout(stacked: Bool) {
        isUsingStackedStats = stacked

        statsRowView.snp.updateConstraints { make in
            make.height.equalTo(stacked ? kCompactStatsRowHeight : kStatsRowHeight)
        }

        totalWordsCard.snp.remakeConstraints { make in
            make.top.leading.equalToSuperview()
            if stacked {
                make.trailing.equalToSuperview()
                make.height.equalTo(kStatsRowHeight)
            } else {
                make.bottom.equalToSuperview()
            }
        }

        progressCard.snp.remakeConstraints { make in
            if stacked {
                make.top.equalTo(totalWordsCard.snp.bottom).offset(kSpacing)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(kStatsRowHeight)
            } else {
                make.top.bottom.equalToSuperview()
                make.leading.equalTo(totalWordsCard.snp.trailing).offset(kSpacing)
                make.width.equalTo(totalWordsCard)
            }
        }

        streakCard.snp.remakeConstraints { make in
            if stacked {
                make.top.equalTo(progressCard.snp.bottom).offset(kSpacing)
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(kStatsRowHeight)
            } else {
                make.top.bottom.trailing.equalToSuperview()
                make.leading.equalTo(progressCard.snp.trailing).offset(kSpacing)
                make.width.equalTo(totalWordsCard)
            }
        }
    }
    
    // MARK: - Public Methods
    
    func updateStatistics(totalWords: Int, days: Int, todayCount: Int, todayGoal: Int, trendPoints: [LLTrendPoint]) {
        totalWordsCard?.updateNumber("\(totalWords)")
        streakCard?.updateNumber("\(days)")
        progressCard?.updateProgress(current: todayCount, total: todayGoal)
        trendCard?.update(points: trendPoints)
    }
}

private final class _StatFlippedView: NSView {
    override var isFlipped: Bool { true }
}
