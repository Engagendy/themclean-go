import Foundation
import UniformTypeIdentifiers

struct ReviewFile: Identifiable, Hashable {
    enum Risk: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
    }

    enum Category: String, CaseIterable {
        case image = "Images"
        case video = "Videos"
        case document = "Documents"
        case archive = "Archives"
        case duplicate = "Duplicates"
        case large = "Large Files"
        case other = "Other"
    }

    let id: UUID
    let url: URL
    let name: String
    let size: Int64
    let modifiedAt: Date?
    let contentType: UTType?
    let category: Category
    let risk: Risk
    var isSelected: Bool
    var isStaged: Bool
    var assetIdentifier: String? = nil

    var isPhotoLibraryItem: Bool {
        assetIdentifier != nil
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}
