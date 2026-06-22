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
    
    private let chartPlaceholder = LLTrendPreviewView()
    
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
        addSubview(chartPlaceholder)
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

        chartPlaceholder.snp.makeConstraints { make in
            make.top.equalTo(placeholderText.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(18)
        }
    }
}

private final class LLTrendPreviewView: NSView {
    override var isFlipped: Bool { true }

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

        let inset: CGFloat = 18
        let plotRect = bounds.insetBy(dx: inset, dy: inset)
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

        let points: [CGFloat] = [0.42, 0.38, 0.53, 0.48, 0.66, 0.61, 0.76]
        let line = NSBezierPath()
        for (index, value) in points.enumerated() {
            let x = plotRect.minX + CGFloat(index) * plotRect.width / CGFloat(points.count - 1)
            let y = plotRect.maxY - value * plotRect.height
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
    }
}
