//
//  LLWordLibraryCardItem.swift
//  LearnLanguage
//
//  Created by Admin on 2026/2/12.
//

import AppKit
import SnapKit

// MARK: - LLWordLibraryCardItem (CollectionView Item)

class LLWordLibraryCardItem: NSCollectionViewItem {
    
    private let cardView = LLWordLibraryCardView(frame: .zero)
    private var wordList: WordList?
    private var onCardClicked: ((WordList) -> Void)?
    
    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        
        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            // 不再使用选中状态
            cardView.isSelected = false
        }
    }
    
    func configure(with wordList: WordList, onClicked: @escaping (WordList) -> Void) {
        self.wordList = wordList
        self.onCardClicked = onClicked
        cardView.data = wordList
        
        // 从数据库获取学习进度
        do {
            let stats = try LLDatabaseManager.shared.getWordListProgressStats(wordListId: wordList.id)
            cardView.learnedCount = stats.learned
            LLLogger.debug("📊 词库 \(wordList.name) 学习进度：\(stats.learned)/\(stats.total)")
        } catch {
            LLLogger.error("❌ 获取学习进度失败：\(error)")
            cardView.learnedCount = 0
        }
        
        // 检查是否是当前正在学习的词库
        let currentListId = LLSettingsStore.shared.currentListId
        cardView.isCurrentLearning = (wordList.id == currentListId)
        
        // 设置点击回调
        cardView.onClicked = { [weak self] list in
            self?.onCardClicked?(list)
        }
    }
}
