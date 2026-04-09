import AppKit
import SnapKit

final class LLFilterChipView: NSView {
    
    struct Item {
        let title: String
        let representedValue: String
    }
    
    var onSelectionChanged: ((Int, Item) -> Void)?
    
    private let titleLabel = NSTextField(labelWithString: "")
    private let arrowImageView = NSImageView()
    private(set) var items: [Item] = []
    private(set) var selectedIndex: Int = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = LLAppearanceManager.shared.colors.surfaceContainerLow.cgColor
        layer?.cornerRadius = 18
        
        titleLabel.font = NSFont.inter(12, .semiBold)
        titleLabel.textColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.9)
        titleLabel.alignment = .center
        addSubview(titleLabel)
        
        let arrowImage = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: nil)
        arrowImage?.isTemplate = true
        arrowImageView.image = arrowImage
        arrowImageView.contentTintColor = LLAppearanceManager.shared.colors.secondaryText.withAlphaComponent(0.8)
        arrowImageView.imageScaling = .scaleProportionallyDown
        addSubview(arrowImageView)
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
        }
        
        arrowImageView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel.snp.trailing).offset(8)
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(12)
        }
        
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(showMenu))
        addGestureRecognizer(clickGesture)
    }
    
    func configure(items: [Item], selectedIndex: Int = 0) {
        self.items = items
        self.selectedIndex = max(0, min(selectedIndex, items.count - 1))
        updateTitle()
    }
    
    func setSelectedIndex(_ index: Int) {
        guard items.indices.contains(index) else { return }
        selectedIndex = index
        updateTitle()
    }
    
    private func updateTitle() {
        guard items.indices.contains(selectedIndex) else {
            titleLabel.stringValue = ""
            return
        }
        titleLabel.stringValue = items[selectedIndex].title
    }
    
    @objc private func showMenu() {
        guard !items.isEmpty else { return }
        
        let menu = NSMenu()
        for (index, item) in items.enumerated() {
            let menuItem = NSMenuItem(title: item.title, action: #selector(handleMenuSelection(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.tag = index
            menuItem.state = index == selectedIndex ? .on : .off
            menu.addItem(menuItem)
        }
        
        let location = NSPoint(x: 0, y: bounds.height + 6)
        menu.popUp(positioning: nil, at: location, in: self)
    }
    
    @objc private func handleMenuSelection(_ sender: NSMenuItem) {
        let index = sender.tag
        guard items.indices.contains(index) else { return }
        selectedIndex = index
        updateTitle()
        onSelectionChanged?(index, items[index])
    }
}
