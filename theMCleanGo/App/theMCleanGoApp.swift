import SwiftUI

@main
struct TheMCleanGoApp: App {
    @StateObject private var store = FileReviewStore()
    @AppStorage("appAppearance") private var appAppearance = AppAppearance.system.rawValue
    @State private var isShowingSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(store)
                    .opacity(isShowingSplash ? 0 : 1)

                if isShowingSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(AppAppearance(rawValue: appAppearance)?.colorScheme)
            .task {
                try? await Task.sleep(for: .milliseconds(850))
                withAnimation(.easeOut(duration: 0.22)) {
                    isShowingSplash = false
                }
            }
        }
    }
}
