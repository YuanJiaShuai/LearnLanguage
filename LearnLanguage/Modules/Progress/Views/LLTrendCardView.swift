//
//  LLTrendCardView.swift
//  LearnLanguage
//
//  学习趋势图表卡片视图

import AppKit
import SnapKit

final class LLTrendCardView: NSView {
    
    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Learning Statistics", comment: ""))
        label.font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        label.textColor = LLAppearanceManager.shared.colors.primaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        return label
    }()
    
    private let chartView = LLTrendPreviewView()
    
    private let placeholderText: NSTextField = {
        let label = NSTextField(labelWithString: NSLocalizedString("Trend Chart Placeholder", comment: "").replacingOccurrences(of: "📊 ", with: ""))
        label.font = NSFont.inter(12, .medium)
        label.textColor = LLAppearanceManager.shared.colors.tertiaryText
        label.isEditable = false
        label.isBezeled = false
        label.drawsBackground = false
        label.alignment = .left
        return label
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.backgroundColor = LLAppearanceManager.shared.colors.cardBackground.cgColor
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.6).cgColor
        addSubview(titleLabel)
        addSubview(chartView)
        addSubview(placeholderText)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(22)
        }

        placeholderText.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalTo(titleLabel)
            make.height.equalTo(18)
        }

        chartView.snp.makeConstraints { make in
            make.top.equalTo(placeholderText.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(18)
        }
    }
    
    func update(points: [LLTrendPoint]) {
        chartView.points = points
        let total = points.reduce(0) { $0 + $1.count }
        placeholderText.stringValue = total > 0
            ? String(format: NSLocalizedString("Trend Chart Subtitle", comment: ""), points.count, total)
            : NSLocalizedString("Trend Chart Empty", comment: "")
    }
}

struct LLTrendPoint {
    let label: String
    let count: Int
}

private final class LLTrendPreviewView: NSView {
    override var isFlipped: Bool { true }
    
    var points: [LLTrendPoint] = [] {
        didSet { needsDisplay = true }
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.backgroundColor = LLAppearanceManager.shared.colors.surfaceContainerLow.withAlphaComponent(0.5).cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let horizontalInset: CGFloat = 18
        let topInset: CGFloat = 18
        let bottomInset: CGFloat = 28
        let plotRect = bounds.insetBy(dx: horizontalInset, dy: 0)
            .insetBy(dx: 0, dy: topInset)
            .offsetBy(dx: 0, dy: 0)
        let adjustedPlotRect = NSRect(
            x: plotRect.minX,
            y: topInset,
            width: plotRect.width,
            height: max(0, bounds.height - topInset - bottomInset)
        )
        
        drawGrid(in: adjustedPlotRect)
        
        guard !points.isEmpty else { return }
        drawLine(in: adjustedPlotRect)
        drawLabels(in: adjustedPlotRect)
    }
    
    private func drawGrid(in plotRect: NSRect) {
        guard plotRect.width > 0, plotRect.height > 0 else { return }

        let gridColor = LLAppearanceManager.shared.colors.borderColor.withAlphaComponent(0.55)
        gridColor.setStroke()

        for i in 0...3 {
            let y = plotRect.minY + CGFloat(i) * plotRect.height / 3
            let path = NSBezierPath()
            path.move(to: NSPoint(x: plotRect.minX, y: y))
            path.line(to: NSPoint(x: plotRect.maxX, y: y))
            path.lineWidth = 1
            path.stroke()
        }
    }
    
    private func drawLine(in plotRect: NSRect) {
        let maxCount = max(points.map(\.count).max() ?? 1, 1)
        let normalizedValues = points.map { point in
            CGFloat(point.count) / CGFloat(maxCount)
        }
        
        let line = NSBezierPath()
        for (index, value) in normalizedValues.enumerated() {
            let denominator = max(normalizedValues.count - 1, 1)
            let x = plotRect.minX + CGFloat(index) * plotRect.width / CGFloat(denominator)
            let y = plotRect.maxY - max(0.08, value) * plotRect.height
            let point = NSPoint(x: x, y: y)
            if index == 0 {
                line.move(to: point)
            } else {
                line.line(to: point)
            }
        }
        LLAppearanceManager.shared.colors.accentColor.withAlphaComponent(0.78).setStroke()
        line.lineWidth = 2
        line.lineJoinStyle = .round
        line.lineCapStyle = .round
        line.stroke()
        
        LLAppearanceManager.shared.colors.accentColor.setFill()
        for (index, value) in normalizedValues.enumerated() {
            let denominator = max(normalizedValues.count - 1, 1)
            let x = plotRect.minX + CGFloat(index) * plotRect.width / CGFloat(denominator)
            let y = plotRect.maxY - max(0.08, value) * plotRect.height
            NSBezierPath(ovalIn: NSRect(x: x - 3, y: y - 3, width: 6, height: 6)).fill()
        }
    }
    
    private func drawLabels(in plotRect: NSRect) {
        guard points.count > 1 else { return }
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.inter(10, .medium),
            .foregroundColor: LLAppearanceManager.shared.colors.tertiaryText,
            .paragraphStyle: paragraph
        ]
        
        for (index, point) in points.enumerated() where index == 0 || index == points.count - 1 {
            let x = plotRect.minX + CGFloat(index) * plotRect.width / CGFloat(points.count - 1)
            let rect = NSRect(x: x - 36, y: plotRect.maxY + 7, width: 72, height: 14)
            point.label.draw(in: rect, withAttributes: attrs)
        }
    }
}
