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
        let mainBackground = NSColor(srgbRed: 249/255, green: 249/255, blue: 254/255, alpha: 1)          // #f9f9fe
        let sidebarBackground = NSColor(srgbRed: 249/255, green: 249/255, blue: 254/255, alpha: 0.72)
        let cardBackground = NSColor.white
        let surfaceContainerLowest = NSColor.white                                                          // #ffffff
        let surfaceContainerLow = NSColor(srgbRed: 243/255, green: 243/255, blue: 248/255, alpha: 1)     // #f3f3f8
        let surfaceContainer = NSColor(srgbRed: 237/255, green: 237/255, blue: 242/255, alpha: 1)        // #ededf2
        
        let moduleTitleText = NSColor(srgbRed: 26/255, green: 28/255, blue: 31/255, alpha: 1)            // #1a1c1f
        let primaryText = NSColor(srgbRed: 26/255, green: 28/255, blue: 31/255, alpha: 1)
        let secondaryText = NSColor(srgbRed: 65/255, green: 71/255, blue: 85/255, alpha: 1)              // #414755
        let tertiaryText = NSColor(srgbRed: 113/255, green: 119/255, blue: 134/255, alpha: 1)            // #717786
        
        let accentColor = NSColor(srgbRed: 0, green: 88/255, blue: 188/255, alpha: 1)                    // #0058bc
        let primaryContainer = NSColor(srgbRed: 0, green: 112/255, blue: 235/255, alpha: 1)              // #0070eb
        let accentLightBackground = NSColor(srgbRed: 216/255, green: 226/255, blue: 255/255, alpha: 1)   // #d8e2ff
        let borderColor = NSColor(srgbRed: 193/255, green: 198/255, blue: 215/255, alpha: 0.15)          // #c1c6d7 @ 15%
        let ghostBorder = NSColor.white.withAlphaComponent(0.2)
        let sidebarTintStart = NSColor(srgbRed: 0, green: 88/255, blue: 188/255, alpha: 0.11)
        let sidebarTintEnd = NSColor.white.withAlphaComponent(0.04)
        
        let successColor = NSColor(srgbRed: 0.2, green: 0.78, blue: 0.35, alpha: 1)
        let warningColor = NSColor(srgbRed: 1, green: 0.67, blue: 0, alpha: 1)
        let errorColor = NSColor(srgbRed: 186/255, green: 26/255, blue: 26/255, alpha: 1)                // #ba1a1a
        let errorContainer = NSColor(srgbRed: 1, green: 218/255, blue: 214/255, alpha: 1)                // #ffdad6
        let errorText = NSColor(srgbRed: 147/255, green: 0, blue: 10/255, alpha: 1)                       // #93000a
    }
    
    // MARK: - Typography
    
    struct Typography {
        let largeTitle = NSFont.systemFont(ofSize: 22, weight: .bold)
        let title1 = NSFont.systemFont(ofSize: 20, weight: .bold)
        let title2 = NSFont.systemFont(ofSize: 16, weight: .semibold)
        let title3 = NSFont.systemFont(ofSize: 14, weight: .semibold)

        let body = NSFont.systemFont(ofSize: 14)
        let callout = NSFont.systemFont(ofSize: 13, weight: .medium)
        let subheadline = NSFont.systemFont(ofSize: 12)
        let caption1 = NSFont.systemFont(ofSize: 11, weight: .medium)
        let caption2 = NSFont.systemFont(ofSize: 10, weight: .bold)
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
