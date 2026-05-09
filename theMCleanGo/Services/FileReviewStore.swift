import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class FileReviewStore: ObservableObject {
    @Published private(set) var files: [ReviewFile] = []
    @Published private(set) var stagedFiles: [ReviewFile] = []
    @Published var isScanning = false
    @Published var lastScanSummary = "Select files or folders to begin."

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

    func importURLs(_ urls: [URL]) {
        isScanning = true
        defer { isScanning = false }

        var imported: [ReviewFile] = []
        for url in urls {
            imported.append(contentsOf: scan(url: url))
        }

        files = imported.sorted { $0.size > $1.size }
        lastScanSummary = imported.isEmpty
            ? "No readable files were found."
            : "Reviewed \(imported.count) files totaling \(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))."
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

    func clearSelection() {
        for index in files.indices {
            files[index].isSelected = false
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

    private func scan(url: URL) -> [ReviewFile] {
        let accessGranted = url.startAccessingSecurityScopedResource()
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
        let category = category(for: type, size: size)
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

    private func category(for type: UTType?, size: Int64) -> ReviewFile.Category {
        if size >= 500_000_000 { return .large }
        guard let type else { return .other }
        if type.conforms(to: .image) { return .image }
        if type.conforms(to: .movie) || type.conforms(to: .video) { return .video }
        if type.conforms(to: .archive) { return .archive }
        if type.conforms(to: .pdf) || type.conforms(to: .text) || type.conforms(to: .data) { return .document }
        return .other
    }

    private func risk(for category: ReviewFile.Category, size: Int64) -> ReviewFile.Risk {
        if category == .large || size >= 500_000_000 { return .medium }
        if category == .archive { return .medium }
        return .low
    }
}
