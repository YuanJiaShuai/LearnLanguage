import AppKit
import SnapKit

final class LLInlineGuideTipView: NSView {
    
    private static let viewIdentifier = NSUserInterfaceItemIdentifier("LLInlineGuideTipView")
    
    private let titleLabel: NSTextField = {
        let label = NSTextField(labelWithString: "")
        label.font = NSFont.inter(12, .bold)
        label.textColor = .white
        return label
    }()
    
    private let messageLabel: NSTextField = {
        let label = NSTextField(wrappingLabelWithString: "")
        label.font = NSFont.inter(12, .medium)
        label.textColor = NSColor.white.withAlphaComponent(0.84)
        label.maximumNumberOfLines = 2
        return label
    }()
    
    private let iconWrapView: NSView = {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 11
        view.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.12).cgColor
        return view
    }()
    
    private let iconView: NSImageView = {
        let view = NSImageView()
        view.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
        view.contentTintColor = .white
        return view
    }()
    
    init(title: String, message: String) {
        super.init(frame: .zero)
        titleLabel.stringValue = title
        messageLabel.stringValue = message
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        identifier = Self.viewIdentifier
        wantsLayer = true
        layer?.cornerRadius = 16
        layer?.backgroundColor = NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.18, alpha: 0.96).cgColor
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor
        layer?.shadowColor = NSColor.black.withAlphaComponent(0.22).cgColor
        layer?.shadowOpacity = 1
        layer?.shadowRadius = 14
        layer?.shadowOffset = CGSize(width: 0, height: -4)
        alphaValue = 0
        
        addSubview(iconWrapView)
        iconWrapView.addSubview(iconView)
        addSubview(titleLabel)
        addSubview(messageLabel)
        
        iconWrapView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.top.equalToSuperview().offset(14)
            make.width.height.equalTo(22)
        }
        
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(12)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.left.equalTo(iconWrapView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-14)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalTo(iconWrapView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-14)
            make.bottom.equalToSuperview().offset(-14)
        }
    }
    
    static func show(in containerView: NSView, title: String, message: String, topInset: CGFloat = 14, autoDismissAfter: TimeInterval = 2.4) {
        if let existing = containerView.subviews.first(where: { $0.identifier == viewIdentifier }) {
            existing.removeFromSuperview()
        }
        
        let tipView = LLInlineGuideTipView(title: title, message: message)
        containerView.addSubview(tipView)
        tipView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(topInset)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().multipliedBy(0.86)
            make.width.greaterThanOrEqualTo(220)
        }
        containerView.layoutSubtreeIfNeeded()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            tipView.animator().alphaValue = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissAfter) { [weak tipView] in
            guard let tipView else { return }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                tipView.animator().alphaValue = 0
            } completionHandler: {
                tipView.removeFromSuperview()
            }
        }
    }
}
