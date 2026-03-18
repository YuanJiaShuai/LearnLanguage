//
//  LLShortcutRecorderView.swift
//  LearnLanguage
//
//  快捷键录入框视图
//  用户点击后进入录入模式，捕获键盘组合键
//

import AppKit
import Carbon
import Carbon

final class LLShortcutRecorderView: NSView {

    // MARK: - Properties

    /// 当前快捷键，外部设置初始值
    var keyCombo: LLKeyCombo = .empty {
        didSet { updateDisplay() }
    }

    /// 快捷键变化回调
    var onChanged: ((LLKeyCombo) -> Void)?

    private var isRecording = false

    // MARK: - UI

    private lazy var label: NSTextField = {
        let f = NSTextField(labelWithString: "")
        f.font = NSFont.systemFont(ofSize: 13)
        f.alignment = .center
        f.lineBreakMode = .byClipping
        return f
    }()

    private lazy var clearButton: NSButton = {
        let b = NSButton(title: "✕", target: self, action: #selector(clearShortcut))
        b.bezelStyle = .rounded
        b.isBordered = false
        b.font = NSFont.systemFont(ofSize: 11)
        b.contentTintColor = NSColor.tertiaryLabelColor
        b.isHidden = true
        return b
    }()

    // MARK: - Init

    override init(frame: NSRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        updateAppearance()

        addSubview(label)
        addSubview(clearButton)

        label.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: clearButton.leadingAnchor, constant: -4),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 18),
            clearButton.heightAnchor.constraint(equalToConstant: 18)
        ])

        updateDisplay()
    }

    // MARK: - Display

    private func updateDisplay() {
        if isRecording {
            label.stringValue = NSLocalizedString("Shortcut Recording", comment: "")
            label.textColor = LLAppearanceManager.shared.colors.accentColor
            clearButton.isHidden = true
        } else if keyCombo.isEmpty {
            label.stringValue = NSLocalizedString("Shortcut None", comment: "")
            label.textColor = NSColor.tertiaryLabelColor
            clearButton.isHidden = true
        } else {
            label.stringValue = keyCombo.displayString
            label.textColor = LLAppearanceManager.shared.colors.primaryText
            clearButton.isHidden = false
        }
        updateAppearance()
    }

    private func updateAppearance() {
        if isRecording {
            layer?.borderColor = LLAppearanceManager.shared.colors.accentColor.cgColor
            layer?.backgroundColor = LLAppearanceManager.shared.colors.accentColor.withAlphaComponent(0.08).cgColor
        } else {
            layer?.borderColor = LLAppearanceManager.shared.colors.borderColor.cgColor
            layer?.backgroundColor = LLAppearanceManager.shared.colors.sidebarBackground.cgColor
        }
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    // MARK: - Recording

    private func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
        updateDisplay()
    }

    private func stopRecording() {
        isRecording = false
        window?.makeFirstResponder(nil)
        updateDisplay()
    }

    @objc private func clearShortcut() {
        keyCombo = .empty
        onChanged?(.empty)
        stopRecording()
    }

    // MARK: - Key Events

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        // ESC 取消录入
        if event.keyCode == 53 {
            stopRecording()
            return
        }

        // Delete/Backspace 清除快捷键
        if event.keyCode == 51 || event.keyCode == 117 {
            clearShortcut()
            return
        }

        // 必须包含至少一个修饰键
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasModifier = flags.contains(.command) || flags.contains(.option) ||
                          flags.contains(.control) || flags.contains(.shift)
        guard hasModifier else { return }

        // 构建 LLKeyCombo
        let keyCode = UInt32(event.keyCode)
        let carbonModifiers = carbonModifierFlags(from: flags)
        let display = formatShortcut(flags: flags, keyCode: event.keyCode)

        let combo = LLKeyCombo(keyCode: keyCode, modifiers: carbonModifiers, displayString: display)
        keyCombo = combo
        onChanged?(combo)
        stopRecording()
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else { return }
        // 仅修饰键变化时实时显示
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        var parts: [String] = []
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option)  { parts.append("⌥") }
        if flags.contains(.shift)   { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        label.stringValue = parts.isEmpty
            ? NSLocalizedString("Shortcut Recording", comment: "")
            : parts.joined()
    }

    // MARK: - Helpers

    private func carbonModifierFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option)  { result |= UInt32(optionKey) }
        if flags.contains(.shift)   { result |= UInt32(shiftKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    private func formatShortcut(flags: NSEvent.ModifierFlags, keyCode: UInt16) -> String {
        var result = ""
        if flags.contains(.control) { result += "⌃" }
        if flags.contains(.option)  { result += "⌥" }
        if flags.contains(.shift)   { result += "⇧" }
        if flags.contains(.command) { result += "⌘" }
        result += keyCodeToString(keyCode)
        return result
    }

    private func keyCodeToString(_ keyCode: UInt16) -> String {
        switch keyCode {
        case 0:  return "A"
        case 1:  return "S"
        case 2:  return "D"
        case 3:  return "F"
        case 4:  return "H"
        case 5:  return "G"
        case 6:  return "Z"
        case 7:  return "X"
        case 8:  return "C"
        case 9:  return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
        case 49: return "Space"
        case 51: return "⌫"
        case 53: return "Esc"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 109: return "F10"
        case 111: return "F12"
        case 122: return "F1"
        case 120: return "F2"
        case 99:  return "F3"
        case 118: return "F4"
        default: return "\(keyCode)"
        }
    }
}
