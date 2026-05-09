import SwiftUI
import UniformTypeIdentifiers

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var store: FileReviewStore
    @State private var selectedSection: AppSection? = .dashboard
    @State private var compactSection: AppSection = .dashboard
    @State private var showingImporter = false

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compactTabs
            } else {
                regularSplitView
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

    private var compactTabs: some View {
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

    private var regularSplitView: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .navigationTitle("theMClean Go")
        } detail: {
            sectionView(selectedSection ?? .dashboard)
        }
    }

    @ViewBuilder
    private func sectionView(_ section: AppSection) -> some View {
        switch section {
        case .dashboard:
            DashboardView(showingImporter: $showingImporter)
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
    case dashboard
    case review
    case stage
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .review: "Review"
        case .stage: "Stage"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "chart.pie"
        case .review: "doc.text.magnifyingglass"
        case .stage: "tray.full"
        case .settings: "gearshape"
        }
    }
}
