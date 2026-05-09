import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var store: FileReviewStore
    @Binding var showingImporter: Bool

    var body: some View {
        VStack(spacing: 0) {
            ReviewHeader(showingImporter: $showingImporter)

            if store.files.isEmpty {
                EmptyReviewView(showingImporter: $showingImporter)
            } else {
                List(store.files) { file in
                    FileRow(file: file) {
                        store.toggleSelection(file)
                    }
                }
                .listStyle(.plain)
            }

            SelectionBar()
        }
        .navigationTitle("Review")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    showingImporter = true
                } label: {
                    Label("Import", systemImage: "plus")
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

private struct ReviewHeader: View {
    @EnvironmentObject private var store: FileReviewStore
    @Binding var showingImporter: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("File review")
                        .font(.largeTitle.bold())
                    Text(store.lastScanSummary)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingImporter = true
                } label: {
                    Label("Choose Files", systemImage: "folder.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 20) {
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
    @Binding var showingImporter: Bool

    var body: some View {
        ContentUnavailableView {
            Label("Choose files to review", systemImage: "doc.badge.plus")
        } description: {
            Text("theMClean Go only reviews files and folders you select from the Files app.")
        } actions: {
            Button("Choose Files") {
                showingImporter = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct SelectionBar: View {
    @EnvironmentObject private var store: FileReviewStore

    var body: some View {
        HStack {
            Text("\(store.selectedFiles.count) selected")
                .foregroundStyle(.secondary)

            Spacer()

            Button("Clear") {
                store.clearSelection()
            }
            .disabled(store.selectedFiles.isEmpty)

            Button {
                store.moveSelectionToStage()
            } label: {
                Label("Move to Stage", systemImage: "tray.and.arrow.down")
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
