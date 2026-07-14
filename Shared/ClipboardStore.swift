import Foundation

final class ClipboardStore {
    static let shared = ClipboardStore()
    private let suiteName = "group.com.clipflow.shared"
    private let maxItems = 200

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private var cachedItems: [ClipItem] = []
    private var isLoaded = false

    var allItems: [ClipItem] {
        if !isLoaded { load() }
        return cachedItems
    }

    var pinnedItems: [ClipItem] {
        allItems.filter { $0.isPinned }
    }

    var recentItems: [ClipItem] {
        allItems.filter { !$0.isPinned }
    }

    func load() {
        guard let data = defaults?.data(forKey: "clipboard_history"),
              let items = try? JSONDecoder().decode([ClipItem].self, from: data)
        else {
            cachedItems = []
            isLoaded = true
            return
        }
        cachedItems = items
        isLoaded = true
    }

    func save() {
        guard let data = try? JSONEncoder().encode(cachedItems) else { return }
        defaults?.set(data, forKey: "clipboard_history")
        notifyExtension()
    }

    func insert(_ item: ClipItem) {
        if let existingIndex = cachedItems.firstIndex(where: { $0.content == item.content }) {
            cachedItems.remove(at: existingIndex)
        }
        cachedItems.insert(item, at: 0)
        if cachedItems.count > maxItems {
            cachedItems = Array(cachedItems.prefix(maxItems))
        }
        save()
    }

    func remove(_ item: ClipItem) {
        cachedItems.removeAll { $0.id == item.id }
        save()
    }

    func togglePin(_ item: ClipItem) {
        guard let index = cachedItems.firstIndex(where: { $0.id == item.id }) else { return }
        cachedItems[index].isPinned.toggle()
        if cachedItems[index].isPinned {
            let pinned = cachedItems.remove(at: index)
            cachedItems.insert(pinned, at: 0)
        }
        save()
    }

    func clear() {
        cachedItems = []
        save()
    }

    func search(_ query: String) -> [ClipItem] {
        guard !query.isEmpty else { return allItems }
        return allItems.filter { $0.content.localizedCaseInsensitiveContains(query) }
    }

    var latestItem: ClipItem? {
        allItems.first
    }

    var hasItem(_ content: String) -> Bool {
        cachedItems.contains { $0.content == content }
    }

    private func notifyExtension() {
        #if !KEYBOARD_EXTENSION
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.clipflow.clipboardUpdated" as CFString),
            nil, nil, true
        )
        #endif
    }
}
