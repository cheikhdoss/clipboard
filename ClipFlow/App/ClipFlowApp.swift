import SwiftUI

@main
struct ClipFlowApp: App {
    @State private var clipboardService = ClipboardService()
    @State private var pipManager = PiPManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(clipboardService)
                .environment(pipManager)
                .preferredColorScheme(.dark)
        }
    }
}
