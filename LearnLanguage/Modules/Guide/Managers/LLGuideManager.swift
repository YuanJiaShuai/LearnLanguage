import Foundation

final class LLGuideManager {
    static let shared = LLGuideManager()
    
    private init() {}
    
    private let mmkv = LLMMKVManager.shared
    
    enum Tip: String {
        case translateAddToVocabulary = "guide_tip_translate_add_to_vocabulary"
        case vocabularyNotebookEntry = "guide_tip_vocabulary_notebook_entry"
    }
    
    private enum Key {
        static let hasCompletedWelcomeGuide = "guide_has_completed_welcome"
        static let hasCompletedFirstStudyGuide = "guide_has_completed_first_study"
    }
    
    var shouldShowWelcomeGuide: Bool {
        !mmkv.bool(forKey: Key.hasCompletedWelcomeGuide, defaultValue: false)
    }
    
    var hasCompletedFirstStudyGuide: Bool {
        mmkv.bool(forKey: Key.hasCompletedFirstStudyGuide, defaultValue: false)
    }
    
    func markWelcomeGuideCompleted() {
        mmkv.set(true, forKey: Key.hasCompletedWelcomeGuide)
    }
    
    func markFirstStudyGuideCompleted() {
        mmkv.set(true, forKey: Key.hasCompletedFirstStudyGuide)
    }
    
    func shouldShowTip(_ tip: Tip) -> Bool {
        !mmkv.bool(forKey: tip.rawValue, defaultValue: false)
    }
    
    func markTipShown(_ tip: Tip) {
        mmkv.set(true, forKey: tip.rawValue)
    }
    
    func resetGuideState() {
        mmkv.remove(forKey: Key.hasCompletedWelcomeGuide)
        mmkv.remove(forKey: Key.hasCompletedFirstStudyGuide)
        Tip.allCases.forEach { mmkv.remove(forKey: $0.rawValue) }
    }
}

extension LLGuideManager.Tip: CaseIterable {}

