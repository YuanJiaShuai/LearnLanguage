//
//  LLStatusBarPopoverPanel.swift
//  LearnLanguage
//
//  状态栏点击后弹出的自定义 Panel（替代 NSMenu）
//

import AppKit
import SnapKit

final class LLStatusBarPopoverPanel: NSPanel {

    // MARK: - Singleton

    static let shared = LLStatusBarPopoverPanel()

    // MARK: - Properties

    private var mouseEventMonitor: Any?
    private(set) var isShowing = false

    // MARK: - Init

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 100),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        setupPanel()
    }

    private func setupPanel() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .statusBar
        isMovable = false
        collectionBehavior = [.canJoinAllSpaces, .transient]

        // 毛玻璃背景
        let effect = NSVisualEffectView()
        effect.material = .menu
        effect.blendingMode = .behindWindow
        effect.state = .active
        effect.wantsLayer = true
        effect.layer?.cornerRadius = 10
        effect.layer?.masksToBounds = true
        contentView = effect
    }

    // MARK: - Show / Hide

    /// 在状态栏图标正下方显示 panel
    /// - Parameter statusItemButton: 状态栏按钮，用于计算位置
    func show(relativeTo button: NSView) {
        guard let screen = button.window?.screen ?? NSScreen.main else { return }

        let contentView = LLStatusBarPopoverContentView()
        contentView.onClose = { [weak self] in self?.hide() }
        self.contentView?.subviews.forEach { $0.removeFromSuperview() }
        self.contentView?.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // 计算合适的高度
        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = contentView.preferredHeight

        // 计算 panel 位置：状态栏图标正下方
        let buttonFrame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero
        var originX = buttonFrame.midX - panelWidth / 2
        var originY = buttonFrame.minY - panelHeight - 4

        // 防止超出屏幕左右边界
        let screenFrame = screen.visibleFrame
        if originX + panelWidth > screenFrame.maxX {
            originX = screenFrame.maxX - panelWidth - 4
        }
        if originX < screenFrame.minX {
            originX = screenFrame.minX + 4
        }
        // 防止超出底部
        if originY < screenFrame.minY {
            originY = screenFrame.minY + 4
        }

        setFrame(NSRect(x: originX, y: originY, width: panelWidth, height: panelHeight), display: false)
        orderFront(nil)
        isShowing = true

        // 点击 panel 外部时自动关闭
        startMonitoringOutsideClicks()
    }

    func hide() {
        guard isShowing else { return }
        stopMonitoringOutsideClicks()
        orderOut(nil)
        isShowing = false

        // 重置查词视图
        if let contentView = contentView?.subviews.first as? LLStatusBarPopoverContentView {
            contentView.resetSearch()
        }
    }

    func toggle(relativeTo button: NSView) {
        if isShowing {
            hide()
        } else {
            show(relativeTo: button)
        }
    }

    // MARK: - Outside Click Monitor

    private func startMonitoringOutsideClicks() {
        stopMonitoringOutsideClicks()
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return }
            let clickLocation = NSEvent.mouseLocation
            if !self.frame.contains(clickLocation) {
                self.hide()
            }
        }
    }

    private func stopMonitoringOutsideClicks() {
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
        }
    }

    deinit {
        stopMonitoringOutsideClicks()
    }
}
