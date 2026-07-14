import SwiftUI

struct ContentView: View {
    @Environment(ClipboardService.self) private var service
    @Environment(PiPManager.self) private var pipManager
    @State private var searchText = ""
    @State private var selectedFilter: ClipFilter = .all
    @State private var showSettings = false

    enum ClipFilter: String, CaseIterable {
        case all = "Tout"
        case texts = "Textes"
        case links = "Liens"
        case codes = "Code"
        case pinned = "Épinglés"

        var icon: String {
            switch self {
            case .all: return "square.stack.3d.up"
            case .texts: return "doc.text"
            case .links: return "link"
            case .codes: return "chevron.left.forwardslash.chevron.right"
            case .pinned: return "pin"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                backgroundLayer
                VStack(spacing: 0) {
                    filterSection
                    clipSection
                }
            }
            .navigationTitle("ClipFlow")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Rechercher dans \(service.allItems.count) clips...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 14) {
                        Button(action: { pipManager.toggle() }) {
                            Image(systemName: pipManager.isActive ? "pip.fill" : "pip")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(pipManager.isActive ? .orange : .white.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(.white.opacity(0.08))
                                .clipShape(Circle())
                        }

                        Menu {
                            Button(action: { showSettings = true }) {
                                Label("Réglages", systemImage: "gearshape")
                            }
                            Divider()
                            Button(role: .destructive, action: { service.clear() }) {
                                Label("Tout effacer", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(.white.opacity(0.08))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .onAppear { service.refresh() }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }

    private var backgroundLayer: some View {
        ZStack {
            Color(white: 0.04)
            Circle()
                .fill(.orange.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(x: -100, y: -200)
            Circle()
                .fill(.blue.opacity(0.05))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: 150, y: -100)
        }
        .ignoresSafeArea()
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ClipFilter.allCases, id: \.self) { filter in
                    let active = selectedFilter == filter
                    Button(action: { withAnimation(.spring(duration: 0.35)) { selectedFilter = filter } }) {
                        HStack(spacing: 5) {
                            Image(systemName: filter.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(filter.rawValue)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(active ? Color.orange : .white.opacity(0.06))
                        .foregroundColor(active ? .black : .white.opacity(0.65))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(active ? Color.orange : .white.opacity(0.06), lineWidth: 0.5)
                        )
                        .shadow(color: active ? .orange.opacity(0.3) : .clear, radius: 8, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var clipSection: some View {
        let items = filteredItems

        return Group {
            if items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(items) { item in
                            ClipCard(item: item)
                                .environment(service)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        bottomSpacer
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }
            }
        }
    }

    private var bottomSpacer: some View {
        VStack(spacing: 4) {
            Image(systemName: "circle.hexagongrid")
                .font(.caption)
                .foregroundColor(.white.opacity(0.15))
            Text("\(service.allItems.count) clips • \(service.pinnedItems.count) épinglés")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.15))
        }
        .padding(.vertical, 30)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(.orange.opacity(0.1))
                    .frame(width: 88, height: 88)
                Circle()
                    .stroke(.orange.opacity(0.15), lineWidth: 1)
                    .frame(width: 100, height: 100)

                Image(systemName: service.allItems.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 6) {
                Text(service.allItems.isEmpty ? "Aucun clip" : "Aucun résultat")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(service.allItems.isEmpty
                    ? "Copie du texte et il apparaîtra ici"
                    : "Essaie une autre recherche")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.35))
            }

            if !service.allItems.isEmpty {
                Button("Voir tout") {
                    withAnimation { selectedFilter = .all; searchText = "" }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.orange)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(.orange.opacity(0.1))
                .clipShape(Capsule())
            }

            Spacer()
        }
    }

    private var filteredItems: [ClipItem] {
        var items: [ClipItem]
        switch selectedFilter {
        case .all: items = service.allItems
        case .pinned: items = service.pinnedItems
        case .texts: items = service.allItems.filter { $0.type == .text }
        case .links: items = service.allItems.filter { $0.type == .url }
        case .codes: items = service.allItems.filter { $0.type == .code }
        }
        if !searchText.isEmpty {
            items = items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        }
        return items
    }
}

struct ClipCard: View {
    @Environment(ClipboardService.self) private var service
    let item: ClipItem
    @State private var copied = false
    @State private var isPressed = false

    var body: some View {
        Button(action: copyAction) {
            HStack(spacing: 0) {
                accentStrip

                VStack(alignment: .leading, spacing: 5) {
                    topRow
                    contentPreview
                    if item.isURL, let domain = item.domainFromURL {
                        linkDomain(domain)
                    }
                }
                .padding(.vertical, 11)
                .padding(.leading, 10)
                .padding(.trailing, 12)

                Spacer(minLength: 0)

                copyIcon
                    .padding(.trailing, 14)
            }
        }
        .buttonStyle(.plain)
        .background(cardBackground)
        .padding(.horizontal, 2)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }

    private var accentStrip: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(typeColor)
            .frame(width: 3.5)
            .padding(.vertical, 10)
            .padding(.leading, 6)
    }

    private var topRow: some View {
        HStack(spacing: 6) {
            // Icon
            Image(systemName: item.type.icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(typeColor)
                .frame(width: 18, height: 18)
                .background(typeColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(item.type.rawValue)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(typeColor.opacity(0.8))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(typeColor.opacity(0.1))
                .clipShape(Capsule())

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.1))
                    .clipShape(Capsule())
            }

            Spacer()

            Text(timestampString)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white.opacity(0.25))
                .monospacedDigit()
        }
    }

    private var contentPreview: some View {
        Text(item.preview)
            .font(.system(size: 13, weight: .regular, design: .monospaced))
            .foregroundColor(.white.opacity(0.8))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .lineSpacing(2)
    }

    private func linkDomain(_ domain: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up.right")
                .font(.system(size: 8, weight: .bold))
            Text(domain)
                .font(.system(size: 10, weight: .medium, design: .rounded))
        }
        .foregroundColor(.blue.opacity(0.7))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.blue.opacity(0.08))
        .clipShape(Capsule())
    }

    private var copyIcon: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 30, height: 30)

            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 11, weight: copied ? .bold : .regular))
                .foregroundColor(copied ? .green : .white.opacity(0.3))
        }
    }

    private var cardBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.06), lineWidth: 0.5)
                )

            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.04), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
        }
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }

    private var typeColor: Color {
        switch item.type {
        case .text: return .blue
        case .url: return .green
        case .email: return .purple
        case .phone: return .orange
        case .code: return .pink
        case .image: return .cyan
        }
    }

    private var timestampString: String {
        let interval = -item.timestamp.timeIntervalSinceNow
        if interval < 60 { return "à l'instant" }
        if interval < 3600 { return "il y a \(Int(interval / 60))min" }
        if interval < 86400 { return "il y a \(Int(interval / 3600))h" }
        return item.timestamp.formatted(date: .abbreviated, time: .omitted)
    }

    private func copyAction() {
        service.copyToClipboard(item)
        withAnimation(.spring(duration: 0.35)) { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.spring(duration: 0.35)) { copied = false }
        }
    }
}
