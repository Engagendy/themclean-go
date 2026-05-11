import SwiftUI

struct ReviewView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var store: FileReviewStore
    @Binding var showingImporter: Bool

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                CompactReviewView(showingImporter: $showingImporter)
            } else {
                RegularReviewView(showingImporter: $showingImporter)
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(horizontalSizeClass == .compact ? .inline : .large)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                FilterMenu()
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingImporter = true
                } label: {
                    Label("Scan", systemImage: "folder.badge.plus")
                }

                Button {
                    store.selectAllLargeFiles()
                } label: {
                    Label("Large", systemImage: "line.3.horizontal.decrease.circle")
                }
                .disabled(store.files.isEmpty)
            }
        }
    }
}

private struct CompactReviewView: View {
    @EnvironmentObject private var store: FileReviewStore
    @Binding var showingImporter: Bool

    var body: some View {
        VStack(spacing: 0) {
            if store.files.isEmpty {
                ScrollView {
                    EmptyReviewView(showingImporter: $showingImporter, compact: true)
                }
                .scrollIndicators(.hidden)
            } else {
                CompactSummaryBar()

                List(store.filteredFiles) { file in
                    NavigationLink {
                        FilePreviewView(file: file)
                    } label: {
                        FileRow(file: file) {
                            store.toggleSelection(file)
                        }
                    }
                }
                .listStyle(.plain)
            }

            SelectionBar()
        }
    }
}

private struct RegularReviewView: View {
    @EnvironmentObject private var store: FileReviewStore
    @Binding var showingImporter: Bool

    var body: some View {
        VStack(spacing: 0) {
            ReviewHeader(showingImporter: $showingImporter)

            if store.files.isEmpty {
                EmptyReviewView(showingImporter: $showingImporter, compact: false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            } else {
                List(store.filteredFiles) { file in
                    NavigationLink {
                        FilePreviewView(file: file)
                    } label: {
                        FileRow(file: file) {
                            store.toggleSelection(file)
                        }
                    }
                }
                .listStyle(.plain)
            }

            SelectionBar()
        }
    }
}

private struct ReviewHeader: View {
    @EnvironmentObject private var store: FileReviewStore
    @Binding var showingImporter: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("File review")
                        .font(.title.bold())
                    Text(store.lastScanSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Button {
                    showingImporter = true
                } label: {
                    Label("Scan", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }

            HStack(spacing: 12) {
                MetricView(title: "Files", value: "\(store.files.count)")
                MetricView(title: "Selected", value: ByteCountFormatter.string(fromByteCount: store.selectedSize, countStyle: .file))
                MetricView(title: "Stage", value: "\(store.stagedFiles.count)")
            }
        }
        .padding()
        .background(.thinMaterial)
    }
}

private struct EmptyReviewView: View {
    @EnvironmentObject private var store: FileReviewStore
    @Binding var showingImporter: Bool
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 62, height: 62)
                .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Scan files to review")
                    .font(.title2.bold())
                Text("Choose local device storage, Downloads, iCloud Drive, or another folder from Files.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(store.lastScanSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Scan") {
                showingImporter = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            VStack(alignment: .leading, spacing: 12) {
                OnboardingRow(icon: "folder", title: "Pick from Files", text: "Select local device storage, Downloads, or selected documents.")
                OnboardingRow(icon: "line.3.horizontal.decrease.circle", title: "Review by size", text: "Sort through large files, archives, media, and documents.")
                OnboardingRow(icon: "tray.and.arrow.down", title: "Use Stage first", text: "Move selected items to Stage before final action.")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, compact ? 22 : 24)
        .padding(.top, compact ? 22 : 34)
        .padding(.bottom, compact ? 110 : 20)
        .frame(maxWidth: 620, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct FilterMenu: View {
    @EnvironmentObject private var store: FileReviewStore

    var body: some View {
        Menu {
            Button {
                store.clearFilter()
            } label: {
                Label("All Files", systemImage: store.selectedCategory == nil ? "checkmark" : "tray.full")
            }

            Divider()

            ForEach(ReviewFile.Category.allCases, id: \.self) { category in
                Button {
                    store.selectedCategory = category
                } label: {
                    Label(category.rawValue, systemImage: store.selectedCategory == category ? "checkmark" : iconName(for: category))
                }
            }
        } label: {
            Label(store.filterTitle, systemImage: "line.3.horizontal.decrease.circle")
        }
        .disabled(store.files.isEmpty)
    }

    private func iconName(for category: ReviewFile.Category) -> String {
        switch category {
        case .image: "photo"
        case .video: "video"
        case .document: "doc.text"
        case .archive: "archivebox"
        case .duplicate: "doc.on.doc"
        case .large: "externaldrive"
        case .other: "doc"
        }
    }
}

private struct CompactSummaryBar: View {
    @EnvironmentObject private var store: FileReviewStore

    var body: some View {
        HStack(spacing: 10) {
            MetricView(title: "Files", value: "\(store.files.count)")
            MetricView(title: "Selected", value: ByteCountFormatter.string(fromByteCount: store.selectedSize, countStyle: .file))
            MetricView(title: "Stage", value: "\(store.stagedFiles.count)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

private struct OnboardingRow: View {
    let icon: String
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.green)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct SelectionBar: View {
    @EnvironmentObject private var store: FileReviewStore

    var body: some View {
        HStack {
            Text("\(store.selectedFiles.count) selected")
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            Button("Clear") {
                store.clearSelection()
            }
            .disabled(store.selectedFiles.isEmpty)

            Button {
                store.moveSelectionToStage()
            } label: {
                Label("Stage", systemImage: "tray.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.selectedFiles.isEmpty)
        }
        .padding()
        .background(.bar)
    }
}

private struct MetricView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
