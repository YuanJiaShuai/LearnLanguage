//
//  LLMainViewController.swift
//  LearnLanguage
//
//  主窗口：Finder 风格布局（左侧导航栏 + 右侧内容区）

import AppKit
import SnapKit

/// 主窗口：Finder 风格的词库管理应用
final class LLMainViewController: NSViewController, SidebarViewControllerDelegate {

    private let splitView = NSSplitView()
    private let sidebarVC = LLSidebarViewController()
    private let contentVC = LLMainContentViewController()

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 900, height: 550))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = LLAppearanceManager.shared.colors.mainBackground.cgColor
        
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        view.addSubview(splitView)
        
        splitView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 左侧导航栏
        sidebarVC.delegate = self
        addChild(sidebarVC)
        splitView.addArrangedSubview(sidebarVC.view)
        sidebarVC.view.snp.makeConstraints { make in
            make.width.equalTo(180)
        }
        
        // 右侧内容区
        addChild(contentVC)
        splitView.addArrangedSubview(contentVC.view)
        
        splitView.setPosition(180, ofDividerAt: 0)
    }
    
    // MARK: - SidebarViewControllerDelegate
    
    func sidebarViewController(_ vc: LLSidebarViewController, didSelectModule module: SidebarModule) {
        contentVC.switchModule(to: module)
    }
    
    func sidebarViewController(_ vc: LLSidebarViewController, didSelectCurrentWordList: WordList?) {
        contentVC.switchModule(to: .wordList)
    }
    
    func sidebarViewController(_ vc: LLSidebarViewController, didSelectWrongWords: ()) {
        contentVC.switchModule(to: .learningRecord)
        
        // 延迟一下，确保页面已经切换
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // 切换到复习记录tab
            if let progressVC = self.contentVC.currentProgressTabViewController {
                progressVC.switchToReviewTab()
                // 设置时间筛选为"今天"
                progressVC.setTimeFilter(to: .today)
            }
        }
    }
}
