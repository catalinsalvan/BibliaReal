import Foundation
import Combine

struct Bookmark: Codable, Identifiable {
    var id = UUID()
    let translation: String
    let bookId: Int
    let bookName: String
    let chapter: Int
    let addedAt: Date

    var label: String { "\(bookName) \(chapter)" }
}

final class BookmarkStore: ObservableObject {
    static let shared = BookmarkStore()
    @Published private(set) var bookmarks: [Bookmark] = []

    private let key = "bookmarks_v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) {
            bookmarks = decoded
        }
    }

    func isBookmarked(translation: Translation, bookId: Int, chapter: Int) -> Bool {
        bookmarks.contains {
            $0.translation == translation.rawValue && $0.bookId == bookId && $0.chapter == chapter
        }
    }

    func toggle(translation: Translation, bookId: Int, bookName: String, chapter: Int) {
        if let idx = bookmarks.firstIndex(where: {
            $0.translation == translation.rawValue && $0.bookId == bookId && $0.chapter == chapter
        }) {
            bookmarks.remove(at: idx)
        } else {
            bookmarks.insert(Bookmark(
                translation: translation.rawValue,
                bookId: bookId,
                bookName: bookName,
                chapter: chapter,
                addedAt: Date()
            ), at: 0)
        }
        persist()
    }

    func remove(at offsets: IndexSet) {
        for index in offsets.sorted().reversed() {
            bookmarks.remove(at: index)
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
