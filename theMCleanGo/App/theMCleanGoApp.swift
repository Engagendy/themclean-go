import SwiftUI

@main
struct TheMCleanGoApp: App {
    @StateObject private var store = FileReviewStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
