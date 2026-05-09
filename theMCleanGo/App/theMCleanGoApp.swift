import SwiftUI

@main
struct TheMCleanGoApp: App {
    @StateObject private var store = FileReviewStore()
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @State private var isReady = false
    @State private var didScheduleStartup = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isReady {
                    RootView()
                        .environmentObject(store)
                        .transition(.opacity)
                } else {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(AppAppearance(rawValue: appAppearance)?.colorScheme)
            .onAppear {
                guard !didScheduleStartup else { return }
                didScheduleStartup = true
                DispatchQueue.main.async {
                    showApp()
                }
            }
        }
    }

    private func showApp() {
        guard !isReady else { return }
        withAnimation(.easeOut(duration: 0.12)) {
            isReady = true
        }
    }
}
