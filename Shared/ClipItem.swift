import Foundation

struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let type: ClipType
    let timestamp: Date
    var isPinned: Bool
    var category: String?

    init(id: UUID = UUID(), content: String, type: ClipType = .text, timestamp: Date = Date(), isPinned: Bool = false, category: String? = nil) {
        self.id = id
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.category = category
    }

    var preview: String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(80))
    }

    var isURL: Bool {
        guard let url = URL(string: content), url.scheme != nil else { return false }
        return true
    }

    var domainFromURL: String? {
        guard isURL, let url = URL(string: content) else { return nil }
        return url.host
    }
}

enum ClipType: String, Codable, CaseIterable {
    case text
    case url
    case email
    case phone
    case code
    case image

    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .url: return "link"
        case .email: return "envelope"
        case .phone: return "phone"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .image: return "photo"
        }
    }
}
