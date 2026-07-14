import UIKit
import Combine

@Observable
final class ClipboardService {
    var latestItem: ClipItem?

    private var lastChangeCount: Int = UIPasteboard.general.changeCount
    private var timer: Timer?
    private let store = ClipboardStore.shared

    init() {
        loadExisting()
        startMonitoring()
    }

    private func loadExisting() {
        store.load()
        latestItem = store.latestItem
    }

    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    private func checkClipboard() {
        let current = UIPasteboard.general.changeCount
        guard current > lastChangeCount else { return }
        lastChangeCount = current

        guard let content = UIPasteboard.general.string, !content.isEmpty else { return }

        let type = detectType(content)
        let item = ClipItem(content: content, type: type)

        guard !store.hasItem(content) else { return }

        store.insert(item)
        latestItem = item
        Haptics.copy()
    }

    func copyToClipboard(_ item: ClipItem) {
        UIPasteboard.general.string = item.content
        Haptics.copy()
        if let index = store.allItems.firstIndex(where: { $0.id == item.id }) {
            store.allItems[index].timestamp = Date()
        }
    }

    private func detectType(_ content: String) -> ClipType {
        if content.hasPrefix("http://") || content.hasPrefix("https://") {
            return .url
        }
        if content.contains("@") && content.contains(".") {
            return .email
        }
        let digits = content.filter { $0.isNumber }
        if digits.count >= 8 && content.count - digits.count <= 3 {
            return .phone
        }
        if content.contains("{") || content.contains("func ") || content.contains("import ") || content.contains("```") {
            return .code
        }
        return .text
    }

    var allItems: [ClipItem] { store.allItems }
    var pinnedItems: [ClipItem] { store.pinnedItems }
    var recentItems: [ClipItem] { store.recentItems }

    func search(_ query: String) -> [ClipItem] { store.search(query) }
    func togglePin(_ item: ClipItem) { store.togglePin(item); loadExisting() }
    func remove(_ item: ClipItem) { store.remove(item); loadExisting() }
    func clear() { store.clear(); latestItem = nil }
    func refresh() { store.load(); latestItem = store.latestItem }
}
