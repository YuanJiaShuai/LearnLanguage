//
//  LLClipboardMonitor.swift
//  LearnLanguage
//
//  剪贴板监听器（移植自 TranslateP/ClipboardMonitor）
//  监听剪贴板变化，区分图片和文字，分别回调。
//

import AppKit

final class LLClipboardMonitor {

    // MARK: - Callbacks

    /// 检测到图片时回调（主线程）
    var onImageDetected: ((NSImage) -> Void)?

    /// 检测到文字时回调（主线程）
    var onTextDetected: ((String) -> Void)?

    // MARK: - Private

    private var timer: Timer?
    private var lastChangeCount: Int = 0

    // MARK: - Public

    /// 开始监听
    func startMonitoring() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        LLLogger.debug("📋 剪贴板监听已启动")
    }

    /// 停止监听
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        LLLogger.debug("📋 剪贴板监听已停止")
    }

    // MARK: - Private

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if let image = imageFromPasteboard() {
            onImageDetected?(image)
        } else if let text = pasteboard.string(forType: .string), !text.isEmpty {
            onTextDetected?(text)
        }
    }

    private func imageFromPasteboard() -> NSImage? {
        let pasteboard = NSPasteboard.general

        let imageTypes: [NSPasteboard.PasteboardType] = [
            .png, .tiff,
            NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("com.compuserve.gif"),
            NSPasteboard.PasteboardType("public.heif"),
        ]

        for type in imageTypes {
            if let data = pasteboard.data(forType: type),
               let image = NSImage(data: data) {
                return image
            }
        }

        // 检查文件路径
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            let imageExts = ["png", "jpg", "jpeg", "gif", "tiff", "tif", "bmp", "webp", "heif", "heic"]
            for url in urls where imageExts.contains(url.pathExtension.lowercased()) {
                if let image = NSImage(contentsOf: url) {
                    return image
                }
            }
        }

        return nil
    }

    deinit {
        stopMonitoring()
    }
}
