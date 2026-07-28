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
                dashboardLists
            }
            .padding(.horizontal, horizontalSizeClass == .compact ? 20 : 28)
            .padding(.top, 18)
            .padding(.bottom, 110)
            .frame(maxWidth: contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(horizontalSizeClass == .compact ? .inline : .large)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingImporter = true
                } label: {
                    Label("Scan Files", systemImage: "folder.badge.plus")
                }

                Button {
                    Task { await store.scanPhotoLibrary() }
                } label: {
                    Label("Scan Photos", systemImage: "photo.on.rectangle.angled")
                }
            }
        }
    }

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .compact ? 760 : 1160
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "link.circle.fill")
                        .font(.system(size: horizontalSizeClass == .compact ? 34 : 40, weight: .semibold))
                        .foregroundStyle(.green)

                    Text("Scan a Files location")
                        .font(horizontalSizeClass == .compact ? .title.bold() : .largeTitle.bold())
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("Press Scan Files to choose local device storage, iCloud Drive, Downloads, or another folder from Files. Or scan your Photos library to review photos and videos.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                showingImporter = true
            } label: {
                Label("Scan Files Location", systemImage: "folder.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button {
                Task { await store.scanPhotoLibrary() }
            } label: {
                Label("Scan Photos & Media", systemImage: "photo.on.rectangle.angled")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(store.isScanning)
        }
    }

    private var metrics: some View {
        LazyVGrid(columns: metricColumns, spacing: 12) {
            DashboardMetric(title: "Reviewed", value: "\(store.files.count)", detail: "files")
            DashboardMetric(title: "Potential", value: ByteCountFormatter.string(fromByteCount: store.totalSize, countStyle: .file), detail: "selected location")
            NavigationLink {
                LargeFilesView()
            } label: {
                DashboardMetric(title: "Large Files", value: "\(store.largeFiles.count)", detail: ByteCountFormatter.string(fromByteCount: store.largeFilesSize, countStyle: .file))
            }
            .buttonStyle(.plain)
            .disabled(store.largeFiles.isEmpty)
            DashboardMetric(title: "Selected", value: ByteCountFormatter.string(fromByteCount: store.selectedSize, countStyle: .file), detail: "\(store.selectedFiles.count) files")
            DashboardMetric(title: "Stage", value: ByteCountFormatter.string(fromByteCount: store.stageSize, countStyle: .file), detail: "\(store.stagedFiles.count) files")
        }
    }

    private var metricColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
        return [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    }

    @ViewBuilder
    private var charts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Analysis")
                .font(.title3.bold())

            if store.categories.isEmpty {
                EmptyDashboardRow(title: "No chart yet", detail: "Choose files or a folder to build the storage chart.")
            } else {
                chartContent
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private var chartContent: some View {
        if horizontalSizeClass == .compact {
            VStack(alignment: .leading, spacing: 18) {
                categoryDonutChart
                categoryBarChart
            }
        } else {
            HStack(alignment: .top, spacing: 22) {
                categoryDonutChart
                    .frame(maxWidth: 430)
                categoryBarChart
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var categoryDonutChart: some View {
        Chart(store.categories, id: \.category) { item in
            SectorMark(
                angle: .value("Size", item.size),
                innerRadius: .ratio(0.58),
                angularInset: 1.5
            )
            .foregroundStyle(by: .value("Category", item.category.rawValue))
        }
        .chartLegend(position: .bottom, alignment: .leading)
        .frame(height: horizontalSizeClass == .compact ? 220 : 300)
    }

    private var categoryBarChart: some View {
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
        .frame(height: max(horizontalSizeClass == .compact ? 160 : 300, CGFloat(store.categories.count) * 34))
    }

    @ViewBuilder
    private var dashboardLists: some View {
        if horizontalSizeClass == .compact {
            categorySection
            largestFilesSection
        } else {
            HStack(alignment: .top, spacing: 28) {
                categorySection
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                largestFilesSection
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var storageAccessNote: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Storage access", systemImage: "lock.shield")
                .font(.headline)
            Text("iOS requires you to grant access first. Choose local device storage in the Files picker to scan local documents, or choose iCloud Drive, Downloads, or a provider folder.")
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
            HStack {
                Text("Largest files")
                    .font(.title3.bold())

                Spacer()

                NavigationLink("View all") {
                    LargeFilesView()
                }
                .disabled(store.largeFiles.isEmpty)
            }

            if store.largestFiles.isEmpty {
                EmptyDashboardRow(title: "Nothing to show", detail: "Large files appear here after analysis.")
            } else {
                ForEach(store.largestFiles) { file in
                    NavigationLink {
                        FilePreviewView(file: file)
                    } label: {
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
                    }
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
                .font(.headline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
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
