import SwiftUI

struct LargeFilesView: View {
    @EnvironmentObject private var store: FileReviewStore

    var body: some View {
        List {
            if store.largeFiles.isEmpty {
                ContentUnavailableView(
                    "No large files",
                    systemImage: "externaldrive",
                    description: Text("Press Scan from the Dashboard and choose a Files location. Files over 100 MB appear here.")
                )
            } else {
                Section {
                    ForEach(store.largeFiles) { file in
                        NavigationLink {
                            FilePreviewView(file: file)
                        } label: {
                            FileRow(file: file) {
                                store.toggleSelection(file)
                            }
                        }
                    }
                } header: {
                    Text("\(store.largeFiles.count) files - \(ByteCountFormatter.string(fromByteCount: store.largeFilesSize, countStyle: .file))")
                } footer: {
                    Text("Tap a row to preview it. Tap the circle to select it for Stage.")
                }
            }
        }
        .navigationTitle("Large Files")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    store.select(store.largeFiles)
                } label: {
                    Label("Select All", systemImage: "checkmark.circle")
                }
                .disabled(store.largeFiles.isEmpty)

                Button {
                    store.moveSelectionToStage()
                } label: {
                    Label("Stage", systemImage: "tray.and.arrow.down")
                }
                .disabled(store.selectedFiles.isEmpty)
            }
        }
    }
}
