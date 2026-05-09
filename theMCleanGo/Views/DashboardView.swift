import Charts
import SwiftUI

struct DashboardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var store: FileReviewStore
    @Binding var showingImporter: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero
                metrics
                charts
                storageAccessNote
                categorySection
                largestFilesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 110)
            .frame(maxWidth: 760, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(horizontalSizeClass == .compact ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingImporter = true
                } label: {
                    Label("Analyze", systemImage: "folder.badge.plus")
                }
            }
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 8) {
                Text("Analyze files you choose")
                    .font(horizontalSizeClass == .compact ? .title.bold() : .largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Text("iPhone and iPad apps cannot scan the whole device storage. Choose a folder or files from Files, and theMClean Go will analyze what you grant.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                showingImporter = true
            } label: {
                Label("Choose Files or Folder", systemImage: "folder.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var metrics: some View {
        LazyVGrid(columns: metricColumns, spacing: 12) {
            DashboardMetric(title: "Reviewed", value: "\(store.files.count)", detail: "files")
            DashboardMetric(title: "Potential", value: ByteCountFormatter.string(fromByteCount: store.totalSize, countStyle: .file), detail: "selected location")
            DashboardMetric(title: "Selected", value: ByteCountFormatter.string(fromByteCount: store.selectedSize, countStyle: .file), detail: "\(store.selectedFiles.count) files")
            DashboardMetric(title: "Stage", value: ByteCountFormatter.string(fromByteCount: store.stageSize, countStyle: .file), detail: "\(store.stagedFiles.count) files")
        }
    }

    private var metricColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible())]
        }
        return [GridItem(.flexible()), GridItem(.flexible())]
    }

    @ViewBuilder
    private var charts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis")
                .font(.title3.bold())

            if store.categories.isEmpty {
                EmptyDashboardRow(title: "No chart yet", detail: "Choose files or a folder to build the storage chart.")
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    Chart(store.categories, id: \.category) { item in
                        SectorMark(
                            angle: .value("Size", item.size),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .foregroundStyle(by: .value("Category", item.category.rawValue))
                    }
                    .chartLegend(position: .bottom, alignment: .leading)
                    .frame(height: horizontalSizeClass == .compact ? 220 : 260)

                    Chart(store.categories, id: \.category) { item in
                        BarMark(
                            x: .value("Size", item.size),
                            y: .value("Category", item.category.rawValue)
                        )
                        .foregroundStyle(.green)
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let bytes = value.as(Int64.self) {
                                    Text(ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file))
                                }
                            }
                        }
                    }
                    .frame(height: max(160, CGFloat(store.categories.count) * 34))
                }
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var storageAccessNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Storage access", systemImage: "lock.shield")
                .font(.headline)
            Text("For App Store safety and iOS privacy, the app only analyzes user-selected Files locations. To review more storage, choose a broader folder such as iCloud Drive, On My iPhone, Downloads, or a provider folder that exposes its files.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Categories")
                .font(.title3.bold())

            if store.categories.isEmpty {
                EmptyDashboardRow(title: "No analysis yet", detail: "Choose files or a folder to see categories.")
            } else {
                ForEach(store.categories, id: \.category) { item in
                    HStack {
                        Text(item.category.rawValue)
                            .font(.body.weight(.medium))
                        Spacer()
                        Text("\(item.count)")
                            .foregroundStyle(.secondary)
                        Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private var largestFilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Largest files")
                .font(.title3.bold())

            if store.largestFiles.isEmpty {
                EmptyDashboardRow(title: "Nothing to show", detail: "Large files appear here after analysis.")
            } else {
                ForEach(store.largestFiles) { file in
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(file.name)
                                .lineLimit(1)
                            Text(file.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(file.formattedSize)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    Divider()
                }
            }
        }
    }
}

private struct DashboardMetric: View {
    let title: String
    let value: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct EmptyDashboardRow: View {
    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.body.weight(.medium))
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
