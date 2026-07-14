import SwiftUI

struct SettingsView: View {
    @Environment(ClipboardService.self) private var service
    @Environment(\.dismiss) private var dismiss
    @State private var cloudService = CloudKitService()
    @State private var iCloudReady = false
    @State private var hapticOn = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color(white: 0.04).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        profileHeader
                        syncCard
                        preferencesCard
                        statsCard
                        aboutCard
                    }
                    .padding(16)
                }
            }
            .navigationTitle("ClipFlow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                        .foregroundColor(.orange)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { iCloudReady = await cloudService.enableAccountStatus() }
    }

    private var profileHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.12))
                    .frame(width: 72, height: 72)
                Circle()
                    .stroke(.orange.opacity(0.2), lineWidth: 1)
                    .frame(width: 80, height: 80)

                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 30, weight: .light))
                    .foregroundColor(.orange)
            }

            VStack(spacing: 2) {
                Text("ClipFlow")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(service.allItems.count) clips • \(service.pinnedItems.count) épinglés")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var syncCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: iCloudReady ? "icloud.fill" : "icloud.slash")
                    .font(.system(size: 16))
                    .foregroundColor(iCloudReady ? .blue : .gray)
                VStack(alignment: .leading, spacing: 1) {
                    Text("iCloud")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(iCloudReady ? "Synchronisé" : "Non connecté")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.35))
                }
                Spacer()

                Button(action: { cloudService.sync() }) {
                    HStack(spacing: 4) {
                        if cloudService.isSyncing {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 12, weight: .medium))
                            Text("Sync")
                                .font(.system(size: 12, weight: .medium))
                        }
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.orange.opacity(0.1))
                    .clipShape(Capsule())
                }
                .disabled(cloudService.isSyncing)
            }

            if let lastSync = cloudService.lastSyncDate {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.2))
                    Text("Dernière sync: \(lastSync.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.2))
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var preferencesCard: some View {
        VStack(spacing: 0) {
            sectionHeader("Préférences")

            Toggle(isOn: $hapticOn) {
                HStack(spacing: 12) {
                    Image(systemName: "haptics")
                        .font(.system(size: 14))
                        .foregroundColor(.orange)
                        .frame(width: 24, height: 24)
                        .background(.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Vibrations")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        Text("Au copier / coller")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
            }
            .tint(.orange)
            .padding(14)
        }
        .background(cardBackground)
    }

    private var statsCard: some View {
        VStack(spacing: 0) {
            sectionHeader("Stockage")

            HStack(spacing: 0) {
                statItem(value: "\(service.allItems.count)", label: "Total", icon: "tray.full", color: .blue)
                Divider().background(.white.opacity(0.06)).frame(width: 1)
                statItem(value: "\(service.pinnedItems.count)", label: "Épinglés", icon: "pin", color: .orange)
                Divider().background(.white.opacity(0.06)).frame(width: 1)
                statItem(value: "\(service.allItems.filter { $0.isURL }.count)", label: "Liens", icon: "link", color: .green)
            }
            .padding(.vertical, 12)
        }
        .background(cardBackground)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
    }

    private var aboutCard: some View {
        VStack(spacing: 0) {
            sectionHeader("À propos")
            VStack(spacing: 10) {
                aboutRow("Version", "1.0.0")
                aboutRow("Extension clavier", "Active")
                aboutRow("PiP flottant", "Disponible")
                aboutRow("iOS", "17.0+")
            }
            .padding(14)
        }
        .background(cardBackground)
    }

    private func aboutRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(value == "Active" ? .green : .white.opacity(0.7))
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 4)
            Spacer()
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(white: 0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.05), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
    }
}
