import AVKit
import PDFKit
import Photos
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct FilePreviewView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FileReviewStore
    let file: ReviewFile
    @State private var isDeleting = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                preview
                actions
                details
            }
            .padding()
            .frame(maxWidth: horizontalSizeClass == .compact ? 760 : 1080, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .navigationTitle(file.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }

            if !file.isPhotoLibraryItem {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: file.url) {
                        Label("Open", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let assetIdentifier = file.assetIdentifier {
            PhotoAssetPreview(assetIdentifier: assetIdentifier, iconName: iconName)
        } else if isImage, let image = loadImage() {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .background(.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else if isPlayableMedia {
            MediaPreview(url: file.url)
                .frame(height: 280)
                .background(.black, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else if isPDF, let data = loadData(limit: 50_000_000) {
            PDFPreview(data: data)
                .frame(minHeight: 420)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else if isText, let text = loadText() {
            ScrollView(.horizontal) {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 220, maxHeight: 420)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            ContentUnavailableView(
                "Preview not available",
                systemImage: iconName,
                description: Text("This file type cannot be previewed directly here yet. Use Open to send it to Files or another app.")
            )
            .frame(maxWidth: .infinity, minHeight: 260)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    @ViewBuilder
    private var actions: some View {
        if !file.isStaged {
            HStack(spacing: 12) {
                Button {
                    store.stage(file)
                    dismiss()
                } label: {
                    Label("Move to Stage", systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if file.isPhotoLibraryItem {
                    Button(role: .destructive) {
                        Task {
                            isDeleting = true
                            defer { isDeleting = false }
                            if await store.deletePhotoFromLibrary(file) {
                                dismiss()
                            }
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isDeleting)
                }
            }
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 14) {
            DetailRow(title: "Name", value: file.name)
            DetailRow(title: "Extension", value: fileExtension.isEmpty ? "None" : fileExtension)
            DetailRow(title: "Category", value: file.category.rawValue)
            DetailRow(title: "Size", value: file.formattedSize)
            DetailRow(title: "Risk", value: file.risk.rawValue)
            if let contentType = file.contentType {
                DetailRow(title: "Type", value: contentType.localizedDescription ?? contentType.identifier)
            }

            if let modifiedAt = file.modifiedAt {
                DetailRow(title: "Modified", value: modifiedAt.formatted(date: .abbreviated, time: .shortened))
            }

            DetailRow(title: "Path", value: file.isPhotoLibraryItem ? "Photos Library" : file.url.path)

            if file.isPhotoLibraryItem {
                Text("This item lives in your Photos library. Stage it in Review, then delete staged photos from the Stage tab — iOS will ask you to confirm.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
            Text("Use Open to share, save, or open the file in another app. iOS does not provide a public API to reveal the exact file location in Files.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var isImage: Bool {
        file.contentType?.conforms(to: .image) == true
    }

    private var isText: Bool {
        file.contentType?.conforms(to: .text) == true || Self.textExtensions.contains(fileExtension)
    }

    private var isPDF: Bool {
        file.contentType?.conforms(to: .pdf) == true || fileExtension == "pdf"
    }

    private var isPlayableMedia: Bool {
        guard let contentType = file.contentType else {
            return Self.mediaExtensions.contains(fileExtension)
        }
        return contentType.conforms(to: .movie)
            || contentType.conforms(to: .video)
            || contentType.conforms(to: .audio)
            || Self.mediaExtensions.contains(fileExtension)
    }

    private var fileExtension: String {
        file.url.pathExtension.lowercased()
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

    private func loadImage() -> UIImage? {
        guard let data = loadData() else { return nil }
        return UIImage(data: data)
    }

    private func loadText() -> String? {
        guard let data = loadData(limit: 80_000) else { return nil }
        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .ascii)
    }

    private func loadData(limit: Int? = nil) -> Data? {
        let accessGranted = file.url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                file.url.stopAccessingSecurityScopedResource()
            }
        }

        guard var data = try? Data(contentsOf: file.url) else { return nil }
        if let limit, data.count > limit {
            data = data.prefix(limit)
        }
        return data
    }

    private static let mediaExtensions: Set<String> = [
        "mp4", "mov", "m4v", "avi", "mkv", "webm", "mpg", "mpeg",
        "mp3", "m4a", "aac", "wav", "aiff", "aif", "flac", "caf"
    ]

    private static let textExtensions: Set<String> = [
        "txt", "md", "markdown", "json", "xml", "csv", "tsv", "yaml", "yml", "plist",
        "log", "sql", "html", "htm", "css", "js", "jsx", "ts", "tsx", "py", "swift",
        "java", "kt", "kts", "go", "rs", "c", "h", "cpp", "hpp", "m", "mm", "sh",
        "zsh", "bash", "env", "ini", "conf", "toml", "lock"
    ]
}

private struct PhotoAssetPreview: View {
    let assetIdentifier: String
    let iconName: String
    @State private var image: UIImage?
    @State private var player: AVPlayer?
    @State private var failed = false

    var body: some View {
        Group {
            if let player {
                PlayerPreview(player: player)
                    .frame(height: 320)
                    .background(.black, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .background(.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else if failed {
                ContentUnavailableView(
                    "Preview not available",
                    systemImage: iconName,
                    description: Text("This item could not be loaded from the Photos library.")
                )
                .frame(maxWidth: .infinity, minHeight: 260)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 260)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .task(id: assetIdentifier) {
            await loadPreview()
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func loadPreview() async {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil).firstObject else {
            failed = true
            return
        }

        if asset.mediaType == .video {
            if let item = await loadPlayerItem(for: asset) {
                player = AVPlayer(playerItem: item)
                return
            }
        }

        image = await loadImage(for: asset)
        failed = image == nil
    }

    private func loadPlayerItem(for asset: PHAsset) async -> AVPlayerItem? {
        await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.deliveryMode = .automatic
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }

    private func loadImage(for asset: PHAsset) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: CGSize(width: 1600, height: 1600),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}

private struct PlayerPreview: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = true
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        controller.player = player
    }
}

private struct MediaPreview: UIViewControllerRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = context.coordinator.player
        controller.allowsPictureInPicturePlayback = true
        return controller
    }

    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) {
        context.coordinator.update(url: url)
        controller.player = context.coordinator.player
    }

    final class Coordinator {
        private(set) var player: AVPlayer
        private var url: URL
        private var hasSecurityAccess = false

        init(url: URL) {
            self.url = url
            self.hasSecurityAccess = url.startAccessingSecurityScopedResource()
            self.player = AVPlayer(url: url)
        }

        deinit {
            player.pause()
            if hasSecurityAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        func update(url newURL: URL) {
            guard newURL != url else { return }
            player.pause()
            if hasSecurityAccess {
                url.stopAccessingSecurityScopedResource()
            }
            url = newURL
            hasSecurityAccess = newURL.startAccessingSecurityScopedResource()
            player = AVPlayer(url: newURL)
        }
    }
}

private struct PDFPreview: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ view: PDFView, context: Context) {
        view.document = PDFDocument(data: data)
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
