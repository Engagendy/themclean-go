import SwiftUI

struct StageView: View {
    @EnvironmentObject private var store: FileReviewStore

    var body: some View {
        List {
            if store.stagedFiles.isEmpty {
                ContentUnavailableView(
                    "Stage is empty",
                    systemImage: "tray",
                    description: Text("Move reviewed items here before taking final action.")
                )
            } else {
                Section {
                    ForEach(store.stagedFiles) { file in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(file.name)
                                    .font(.body.weight(.medium))
                                Text(file.formattedSize)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button("Restore") {
                                store.restoreFromStage(file)
                            }
                            .buttonStyle(.bordered)

                            Button(role: .destructive) {
                                store.removeFromStage(file)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 6)
                    }
                } header: {
                    Text("Ready for final review")
                } footer: {
                    Text("This first mobile build tracks Stage decisions inside the app. Direct file deletion will stay guarded behind explicit confirmation in a later phase.")
                }
            }
        }
        .navigationTitle("Stage")
    }
}
