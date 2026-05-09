import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @EnvironmentObject private var store: FileReviewStore
    @State private var selectedSection: AppSection? = .review
    @State private var compactSection: AppSection = .review
    @State private var showingImporter = false

    var body: some View {
        ViewThatFits {
            NavigationSplitView {
                List(AppSection.allCases, selection: $selectedSection) { section in
                    Label(section.title, systemImage: section.icon)
                        .tag(section)
                }
                .navigationTitle("theMClean Go")
            } detail: {
                sectionView(selectedSection ?? .review)
            }

            TabView(selection: $compactSection) {
                ForEach(AppSection.allCases) { section in
                    NavigationStack {
                        sectionView(section)
                    }
                    .tabItem {
                        Label(section.title, systemImage: section.icon)
                    }
                    .tag(section)
                }
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.item, .folder],
            allowsMultipleSelection: true
        ) { result in
            if case let .success(urls) = result {
                store.importURLs(urls)
            }
        }
    }

    @ViewBuilder
    private func sectionView(_ section: AppSection) -> some View {
        switch section {
        case .review:
            ReviewView(showingImporter: $showingImporter)
        case .stage:
            StageView()
        case .settings:
            SettingsView()
        }
    }
}

private enum AppSection: String, CaseIterable, Identifiable {
    case review
    case stage
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .review: "Review"
        case .stage: "Stage"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .review: "doc.text.magnifyingglass"
        case .stage: "tray.full"
        case .settings: "gearshape"
        }
    }
}
