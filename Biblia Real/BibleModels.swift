import Foundation

enum Translation: String, CaseIterable, Identifiable {
    case rv1960
    case cornilescu

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rv1960: return "RV1960"
        case .cornilescu: return "Cornilescu"
        }
    }

    var language: String {
        switch self {
        case .rv1960: return "Español"
        case .cornilescu: return "Română"
        }
    }
}

struct Book: Identifiable {
    let id: Int
    let name: String
    let chapterCount: Int
}

struct Chapter: Identifiable {
    let number: Int
    var id: Int { number }
    let verses: [Verse]
}

struct Verse: Identifiable {
    let number: Int
    var id: Int { number }
    let text: String
}

struct SearchResult: Identifiable {
    let id = UUID()
    let bookId: Int
    let bookName: String
    let chapter: Int
    let verse: Int
    let text: String

    var reference: String { "\(bookName) \(chapter):\(verse)" }
}
