import SwiftUI

struct FileRow: View {
    let file: ReviewFile
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.green)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(file.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(file.category.rawValue)
                    Text(file.formattedSize)
                    if let modified = file.modifiedAt {
                        Text(modified, style: .date)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            RiskBadge(risk: file.risk)

            Button(action: toggle) {
                Image(systemName: file.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(file.isSelected ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 8)
    }

    private var iconName: String {
        switch file.category {
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

private struct RiskBadge: View {
    let risk: ReviewFile.Risk

    var body: some View {
        Text(risk.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var color: Color {
        switch risk {
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }
}
