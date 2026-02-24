//
//  LLAppearanceManager.swift
//  LearnLanguage
//
//  管理应用的外观和主题（浅色/深色）
//

import AppKit

final class LLAppearanceManager {
    static let shared = LLAppearanceManager()
    
    enum Theme {
        case light
        case dark
        case system
        
        var effectiveAppearance: NSAppearance {
            switch self {
            case .light:
                return NSAppearance(named: .aqua) ?? NSAppearance()
            case .dark:
                return NSAppearance(named: .darkAqua) ?? NSAppearance()
            case .system:
                if #available(macOS 12.0, *) {
                    return NSApp.effectiveAppearance
                } else {
                    return NSAppearance.current
                }
            }
        }
    }
    
    // MARK: - Colors
    
    struct Colors {
        // 与网页设计稿一致 (#f5f5f7 / #fafafa / #e5e5e7 / #007aff)
        /// 主背景、标题栏
        let mainBackground = NSColor(srgbRed: 245/255, green: 245/255, blue: 247/255, alpha: 1)  // #f5f5f7
        /// 侧边栏、卡片背景
        let sidebarBackground = NSColor(srgbRed: 250/255, green: 250/255, blue: 250/255, alpha: 1)  // #fafafa
        let cardBackground = NSColor.white
        
        // 文本色
        let moduleTitleText = NSColor(srgbRed: 29/255, green: 29/255, blue: 31/255, alpha: 1)   // #1d1d1f
        let primaryText = NSColor(srgbRed: 51/255, green: 51/255, blue: 51/255, alpha: 1)      // #333
        let secondaryText = NSColor(srgbRed: 102/255, green: 102/255, blue: 102/255, alpha: 1)   // #666
        let tertiaryText = NSColor(srgbRed: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        
        // 强调色
        let accentColor = NSColor(srgbRed: 0, green: 122/255, blue: 1, alpha: 1)  // #007aff
        /// 导航选中、卡片选中浅底
        let accentLightBackground = NSColor(srgbRed: 232/255, green: 240/255, blue: 254/255, alpha: 1)  // #e8f0fe
        
        // 边框/分隔线（与设计稿 #e5e5e7）
        let borderColor = NSColor(srgbRed: 229/255, green: 229/255, blue: 231/255, alpha: 1)  // #e5e5e7
        
        // 状态色
        let successColor = NSColor(srgbRed: 0.2, green: 0.78, blue: 0.35, alpha: 1)
        let warningColor = NSColor(srgbRed: 1, green: 0.67, blue: 0, alpha: 1)
        /// 错题徽章红 #ff3b30
        let errorColor = NSColor(srgbRed: 1, green: 59/255, blue: 48/255, alpha: 1)
    }
    
    // MARK: - Typography
    
    struct Typography {
        // 尽量与 HTML 原型中 Inter 字体的尺寸与重量匹配
        let largeTitle = NSFont.systemFont(ofSize: 22, weight: .semibold)
        let title1 = NSFont.systemFont(ofSize: 20, weight: .semibold)
        let title2 = NSFont.systemFont(ofSize: 16, weight: .semibold)
        let title3 = NSFont.systemFont(ofSize: 14, weight: .semibold)

        let body = NSFont.systemFont(ofSize: 14)
        let callout = NSFont.systemFont(ofSize: 13, weight: .medium)
        let subheadline = NSFont.systemFont(ofSize: 12)
        let caption1 = NSFont.systemFont(ofSize: 11)
        let caption2 = NSFont.systemFont(ofSize: 10)
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        let xs: CGFloat = 4
        let sm: CGFloat = 8
        let md: CGFloat = 12
        let lg: CGFloat = 16
        let xl: CGFloat = 20
        let xxl: CGFloat = 24
        let xxxl: CGFloat = 28
    }
    
    let colors = Colors()
    let typography = Typography()
    let spacing = Spacing()
    
    private(set) var currentTheme: Theme = .system
    
    func setTheme(_ theme: Theme) {
        currentTheme = theme
        
        // 当设置为 system 时，使用 nil 让应用跟随系统外观
        if theme == .system {
            NSApp.appearance = nil
        } else {
            NSApp.appearance = theme.effectiveAppearance
        }
    }
}

// MARK: - NSButton 扩展，提供预设样式

extension NSButton {
    func applyPrimaryStyle() {
        bezelStyle = .rounded
        controlSize = .regular
        font = LLAppearanceManager.shared.typography.callout
        // NSButton 在 AppKit 上没有 `backgroundColor` 属性 — 使用 layer 背景色
        wantsLayer = true
        layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.cgColor
        setTitleColor(.white)
    }
    
    func applyDefaultStyle() {
        bezelStyle = .rounded
        controlSize = .regular
        font = LLAppearanceManager.shared.typography.callout
        wantsLayer = true
        layer?.backgroundColor = LLAppearanceManager.shared.colors.cardBackground.cgColor
        setTitleColor(LLAppearanceManager.shared.colors.primaryText)
    }
    
    func setTitleColor(_ color: NSColor) {
        let mutableAttributedTitle = NSMutableAttributedString(attributedString: attributedTitle)
        mutableAttributedTitle.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutableAttributedTitle.length))
        attributedTitle = mutableAttributedTitle
    }
}

// MARK: - NSView 扩展，便捷配置

extension NSView {
    func applyCardStyle() {
        wantsLayer = true
        layer?.cornerRadius = 8
        layer?.borderWidth = 1
        layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
        layer?.backgroundColor = LLAppearanceManager.shared.colors.cardBackground.cgColor
        // 轻微阴影以接近 HTML 原型的卡片浮层感
        layer?.shadowColor = NSColor.black.withAlphaComponent(0.06).cgColor
        layer?.shadowOpacity = 1
        layer?.shadowOffset = CGSize(width: 0, height: -2)
        layer?.shadowRadius = 8
    }
    
    func applySeparatorStyle() {
        wantsLayer = true
        layer?.backgroundColor = LLAppearanceManager.shared.colors.borderColor.cgColor
    }
}

// MARK: - NSTextField 扩展

extension NSTextField {
    func applyTitleStyle() {
        font = LLAppearanceManager.shared.typography.title2
        textColor = LLAppearanceManager.shared.colors.primaryText
        isEditable = false
        isBezeled = false
        drawsBackground = false
    }
    
    func applySubtitleStyle() {
        font = LLAppearanceManager.shared.typography.callout
        textColor = LLAppearanceManager.shared.colors.secondaryText
        isEditable = false
        isBezeled = false
        drawsBackground = false
    }
}
