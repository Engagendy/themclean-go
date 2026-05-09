import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var store: FileReviewStore
    @Binding var showingImporter: Bool

    var body: some View {
        VStack(spacing: 0) {
            ReviewHeader(showingImporter: $showingImporter)

            if store.files.isEmpty {
                EmptyReviewView(showingImporter: $showingImporter)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                    Label("Choose Files", systemImage: "folder.badge.plus")
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
    @Binding var showingImporter: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(.green)
                .frame(width: 62, height: 62)
                .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 8) {
                Text("Choose files to review")
                    .font(.title2.bold())
                Text("theMClean Go only reviews files and folders you select from the Files app.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button("Choose Files") {
                showingImporter = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            VStack(alignment: .leading, spacing: 12) {
                OnboardingRow(icon: "folder", title: "Pick from Files", text: "Import a folder, Downloads area, or selected documents.")
                OnboardingRow(icon: "line.3.horizontal.decrease.circle", title: "Review by size", text: "Sort through large files, archives, media, and documents.")
                OnboardingRow(icon: "tray.and.arrow.down", title: "Use Stage first", text: "Move selected items to Stage before final action.")
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 34)
        .padding(.bottom, 20)
        .frame(maxWidth: 620, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
