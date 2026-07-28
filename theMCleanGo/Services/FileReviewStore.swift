import Foundation
import Photos
import SwiftUI
import UniformTypeIdentifiers

struct PhotoScanProgress {
    var completed: Int
    var total: Int
}

@MainActor
final class FileReviewStore: ObservableObject {
    @Published private(set) var files: [ReviewFile] = []
    @Published private(set) var stagedFiles: [ReviewFile] = []
    @Published var isScanning = false
    @Published private(set) var photoScanProgress: PhotoScanProgress?
    @Published var lastScanSummary = "Press Scan and choose local device storage, iCloud Drive, Downloads, or another Files location."
    @Published var selectedCategory: ReviewFile.Category?
    private var scannedAppStorage = false
    private var activeSecurityScopedURLs: [URL] = []

    var selectedFiles: [ReviewFile] {
        files.filter(\.isSelected)
    }

    var selectedSize: Int64 {
        selectedFiles.reduce(0) { $0 + $1.size }
    }

    var totalSize: Int64 {
        files.reduce(0) { $0 + $1.size }
    }

    var stageSize: Int64 {
        stagedFiles.reduce(0) { $0 + $1.size }
    }

    var categories: [(category: ReviewFile.Category, count: Int, size: Int64)] {
        ReviewFile.Category.allCases.compactMap { category in
            let matching = files.filter { $0.category == category }
            guard !matching.isEmpty else { return nil }
            return (category, matching.count, matching.reduce(0) { $0 + $1.size })
        }
        .sorted { $0.size > $1.size }
    }

    var largestFiles: [ReviewFile] {
        Array(files.prefix(5))
    }

    var largeFiles: [ReviewFile] {
        files.filter { $0.category == .large || $0.size >= 100_000_000 }
    }

    var largeFilesSize: Int64 {
        largeFiles.reduce(0) { $0 + $1.size }
    }

    var filteredFiles: [ReviewFile] {
        guard let selectedCategory else { return files }
        return files.filter { $0.category == selectedCategory }
    }

    var filterTitle: String {
        selectedCategory?.rawValue ?? "All Files"
    }

    func clearFilter() {
        selectedCategory = nil
    }

    func importURLs(_ urls: [URL]) {
        isScanning = true
        defer { isScanning = false }

        activateSecurityScopes(for: urls)

        var imported: [ReviewFile] = []
        for url in urls {
            imported.append(contentsOf: scan(url: url, managesSecurityScope: false))
        }

        files = imported.sorted { $0.size > $1.size }
        lastScanSummary = imported.isEmpty
            ? "No readable files were found."
            : "Reviewed \(imported.count) files totaling \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))."
    }

    func scanAppStorageIfNeeded() {
        guard !scannedAppStorage, files.isEmpty else { return }
        scanAppStorage()
    }

    func scanAppStorage() {
        scannedAppStorage = true
        isScanning = true
        defer { isScanning = false }

        let fileManager = FileManager.default
        var roots = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        roots.append(contentsOf: fileManager.urls(for: .cachesDirectory, in: .userDomainMask))
        roots.append(fileManager.temporaryDirectory)

        var seenPaths = Set<String>()
        let imported = roots
            .filter { seenPaths.insert($0.path).inserted }
            .flatMap { scan(url: $0, managesSecurityScope: false) }
            .sorted { $0.size > $1.size }

        guard !imported.isEmpty else {
            if files.isEmpty {
                lastScanSummary = "No files were found in the app storage. Press Scan to choose local device storage, iCloud Drive, Downloads, or another Files location."
            }
            return
        }

        files = imported
        lastScanSummary = "Reviewed app storage: \(imported.count) files totaling \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))."
    }

    func scanPhotoLibrary() async {
        guard !isScanning else { return }
        isScanning = true
        defer {
            isScanning = false
            photoScanProgress = nil
        }

        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        guard status == .authorized || status == .limited else {
            lastScanSummary = "Photos access is off. Allow it in Settings > Privacy & Security > Photos to review photos and media."
            return
        }

        photoScanProgress = PhotoScanProgress(completed: 0, total: 0)

        let imported = await Task.detached(priority: .userInitiated) {
            Self.fetchPhotoLibraryFiles { completed, total in
                Task { @MainActor [weak self] in
                    guard let self, self.isScanning else { return }
                    self.photoScanProgress = PhotoScanProgress(completed: completed, total: total)
                }
            }
        }.value

        files.removeAll(where: \.isPhotoLibraryItem)
        files.append(contentsOf: imported)
        files.sort { $0.size > $1.size }

        lastScanSummary = imported.isEmpty
            ? "No photos or videos were found in the Photos library."
            : "Reviewed \(imported.count) photos and videos totaling \(ByteCountFormatter.string(fromByteCount: imported.reduce(0) { $0 + $1.size }, countStyle: .file))."
    }

    var stagedPhotoLibraryFiles: [ReviewFile] {
        stagedFiles.filter(\.isPhotoLibraryItem)
    }

    func deleteStagedPhotosFromLibrary() async {
        let staged = stagedPhotoLibraryFiles
        let identifiers = staged.compactMap(\.assetIdentifier)
        guard !identifiers.isEmpty else { return }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets)
            }
            let removedIDs = Set(staged.map(\.id))
            stagedFiles.removeAll { removedIDs.contains($0.id) }
            lastScanSummary = "Deleted \(staged.count) items from the Photos library. Deleted items stay in Photos > Recently Deleted for 30 days."
        } catch {
            lastScanSummary = "Photos deletion was canceled or failed."
        }
    }

    nonisolated private static func fetchPhotoLibraryFiles(progress: @escaping @Sendable (Int, Int) -> Void) -> [ReviewFile] {
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        let assets = PHAsset.fetchAssets(with: options)
        let total = assets.count
        progress(0, total)

        var results: [ReviewFile] = []
        assets.enumerateObjects { asset, index, _ in
            if index % 50 == 0 || index == total - 1 {
                progress(index + 1, total)
            }
            guard asset.mediaType == .image || asset.mediaType == .video else { return }

            let resources = PHAssetResource.assetResources(for: asset)
            let size = resources.reduce(Int64(0)) { total, resource in
                total + ((resource.value(forKey: "fileSize") as? Int64) ?? 0)
            }
            let name = resources.first?.originalFilename ?? (asset.mediaType == .video ? "Video" : "Photo")
            let type = UTType(filenameExtension: (name as NSString).pathExtension.lowercased())

            let category: ReviewFile.Category
            if size >= 500_000_000 {
                category = .large
            } else {
                category = asset.mediaType == .video ? .video : .image
            }

            results.append(ReviewFile(
                id: UUID(),
                url: URL(fileURLWithPath: "/Photos Library/\(name)"),
                name: name,
                size: size,
                modifiedAt: asset.modificationDate ?? asset.creationDate,
                contentType: type,
                category: category,
                risk: category == .large ? .medium : .low,
                isSelected: false,
                isStaged: false,
                assetIdentifier: asset.localIdentifier
            ))
        }
        return results
    }

    func toggleSelection(_ file: ReviewFile) {
        guard let index = files.firstIndex(where: { $0.id == file.id }) else { return }
        files[index].isSelected.toggle()
    }

    func selectAllLargeFiles() {
        for index in files.indices {
            files[index].isSelected = files[index].category == .large || files[index].size >= 100_000_000
        }
    }

    func select(_ filesToSelect: [ReviewFile]) {
        let ids = Set(filesToSelect.map(\.id))
        for index in files.indices {
            if ids.contains(files[index].id) {
                files[index].isSelected = true
            }
        }
    }

    func clearSelection() {
        for index in files.indices {
            files[index].isSelected = false
        }
    }

    func stage(_ file: ReviewFile) {
        guard let index = files.firstIndex(where: { $0.id == file.id }) else { return }
        var staged = files.remove(at: index)
        staged.isSelected = false
        staged.isStaged = true
        stagedFiles.append(staged)
        lastScanSummary = "Moved \(staged.name) to Stage."
    }

    func deletePhotoFromLibrary(_ file: ReviewFile) async -> Bool {
        guard let identifier = file.assetIdentifier else { return false }

        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets)
            }
            files.removeAll { $0.id == file.id }
            stagedFiles.removeAll { $0.id == file.id }
            lastScanSummary = "Deleted \(file.name) from the Photos library. It stays in Photos > Recently Deleted for 30 days."
            return true
        } catch {
            return false
        }
    }

    func moveSelectionToStage() {
        let selected = selectedFiles
        let selectedIDs = Set(selected.map(\.id))
        let staged = selected.map { file in
            var copy = file
            copy.isSelected = false
            copy.isStaged = true
            return copy
        }

        stagedFiles.append(contentsOf: staged)
        files.removeAll { selectedIDs.contains($0.id) }
        lastScanSummary = "Moved \(staged.count) items to Stage for review."
    }

    func restoreFromStage(_ file: ReviewFile) {
        guard let index = stagedFiles.firstIndex(where: { $0.id == file.id }) else { return }
        var restored = stagedFiles.remove(at: index)
        restored.isStaged = false
        files.insert(restored, at: 0)
    }

    func removeFromStage(_ file: ReviewFile) {
        stagedFiles.removeAll { $0.id == file.id }
    }

    private func activateSecurityScopes(for urls: [URL]) {
        stopActiveSecurityScopes()
        for url in urls {
            if url.startAccessingSecurityScopedResource() {
                activeSecurityScopedURLs.append(url)
            }
        }
    }

    private func stopActiveSecurityScopes() {
        for url in activeSecurityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        activeSecurityScopedURLs.removeAll()
    }

    private func scan(url: URL, managesSecurityScope: Bool = true) -> [ReviewFile] {
        let accessGranted = managesSecurityScope && url.startAccessingSecurityScopedResource()
        defer {
            if accessGranted {
                url.stopAccessingSecurityScopedResource()
            }
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return []
        }

        if isDirectory.boolValue {
            return scanDirectory(url)
        }

        guard let file = makeReviewFile(url: url) else {
            return []
        }
        return [file]
    }

    private func scanDirectory(_ url: URL) -> [ReviewFile] {
        let keys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .contentTypeKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        return enumerator.compactMap { item in
            guard let fileURL = item as? URL else { return nil }
            return makeReviewFile(url: fileURL)
        }
    }

    private func makeReviewFile(url: URL) -> ReviewFile? {
        guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .contentTypeKey]),
              values.isRegularFile == true
        else {
            return nil
        }

        let size = Int64(values.fileSize ?? 0)
        let type = values.contentType
        let category = category(for: type, extension: url.pathExtension, size: size)
        return ReviewFile(
            id: UUID(),
            url: url,
            name: url.lastPathComponent,
            size: size,
            modifiedAt: values.contentModificationDate,
            contentType: type,
            category: category,
            risk: risk(for: category, size: size),
            isSelected: false,
            isStaged: false
        )
    }

    private func category(for type: UTType?, extension pathExtension: String, size: Int64) -> ReviewFile.Category {
        if size >= 500_000_000 { return .large }
        let ext = pathExtension.lowercased()

        if Self.imageExtensions.contains(ext) { return .image }
        if Self.mediaExtensions.contains(ext) { return .video }
        if Self.archiveExtensions.contains(ext) { return .archive }
        if Self.documentExtensions.contains(ext) || Self.textExtensions.contains(ext) || Self.fontExtensions.contains(ext) { return .document }

        guard let type else { return .other }
        if type.conforms(to: .image) { return .image }
        if type.conforms(to: .movie) || type.conforms(to: .video) || type.conforms(to: .audio) { return .video }
        if type.conforms(to: .archive) { return .archive }
        if type.conforms(to: .pdf) || type.conforms(to: .text) { return .document }
        return .other
    }

    private func risk(for category: ReviewFile.Category, size: Int64) -> ReviewFile.Risk {
        if category == .large || size >= 500_000_000 { return .medium }
        if category == .archive { return .medium }
        return .low
    }

    private static let imageExtensions: Set<String> = [
        "jpg", "jpeg", "png", "heic", "heif", "gif", "tif", "tiff", "bmp", "webp",
        "raw", "dng", "cr2", "cr3", "nef", "arw", "orf", "rw2"
    ]

    private static let mediaExtensions: Set<String> = [
        "mp4", "mov", "m4v", "avi", "mkv", "webm", "mpg", "mpeg",
        "mp3", "m4a", "aac", "wav", "aiff", "aif", "flac", "caf"
    ]

    private static let archiveExtensions: Set<String> = [
        "zip", "rar", "7z", "tar", "gz", "tgz", "bz2", "xz", "dmg", "pkg", "ipa"
    ]

    private static let documentExtensions: Set<String> = [
        "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "pages", "numbers", "key",
        "rtf", "rtfd", "epub"
    ]

    private static let textExtensions: Set<String> = [
        "txt", "md", "markdown", "json", "xml", "csv", "tsv", "yaml", "yml", "plist",
        "log", "sql", "html", "htm", "css", "js", "jsx", "ts", "tsx", "py", "swift",
        "java", "kt", "kts", "go", "rs", "c", "h", "cpp", "hpp", "m", "mm", "sh",
        "zsh", "bash", "env", "ini", "conf", "toml", "lock"
    ]

    private static let fontExtensions: Set<String> = [
        "ttf", "otf", "woff", "woff2"
    ]
}
