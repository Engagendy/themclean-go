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
        .overlay {
            if let progress = store.photoScanProgress {
                PhotoScanOverlay(progress: progress)
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

private struct PhotoScanOverlay: View {
    let progress: PhotoScanProgress

    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                if progress.total > 0 {
                    ProgressView(value: Double(progress.completed), total: Double(progress.total))
                        .progressViewStyle(.linear)
                        .tint(.green)

                    Text("Scanning photos and media")
                        .font(.headline)

                    Text("\(progress.completed.formatted()) of \(progress.total.formatted())")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    ProgressView()
                        .controlSize(.large)

                    Text("Preparing photo library scan")
                        .font(.headline)
                }
            }
            .padding(28)
            .frame(maxWidth: 320)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.2), value: progress.total > 0)
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
