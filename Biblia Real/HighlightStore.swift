import SwiftUI
import Combine

enum HighlightColor: String, CaseIterable, Codable {
    case yellow, green, pink, blue

    var color: Color {
        switch self {
        case .yellow: return .yellow
        case .green:  return .green
        case .pink:   return .pink
        case .blue:   return .blue
        }
    }

    func label(for translation: Translation) -> String {
        let ro = translation == .cornilescu
        switch self {
        case .yellow: return ro ? "Galben"   : "Amarillo"
        case .green:  return ro ? "Verde"    : "Verde"
        case .pink:   return ro ? "Roz"      : "Roz"
        case .blue:   return ro ? "Albastru" : "Azul"
        }
    }
}

struct VerseHighlight: Codable, Identifiable {
    var id = UUID()
    let translation: String
    let bookId: Int
    let chapter: Int
    let verse: Int
    var color: HighlightColor
}

final class HighlightStore: ObservableObject {
    static let shared = HighlightStore()
    @Published private(set) var highlights: [VerseHighlight] = []

    private let key = "verseHighlights_v1"

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([VerseHighlight].self, from: data) {
            highlights = decoded
        }
    }

    func color(translation: Translation, bookId: Int, chapter: Int, verse: Int) -> HighlightColor? {
        highlights.first {
            $0.translation == translation.rawValue &&
            $0.bookId == bookId &&
            $0.chapter == chapter &&
            $0.verse == verse
        }?.color
    }

    func set(_ color: HighlightColor?, translation: Translation, bookId: Int, chapter: Int, verse: Int) {
        highlights.removeAll {
            $0.translation == translation.rawValue &&
            $0.bookId == bookId &&
            $0.chapter == chapter &&
            $0.verse == verse
        }
        if let color {
            highlights.insert(VerseHighlight(
                translation: translation.rawValue,
                bookId: bookId,
                chapter: chapter,
                verse: verse,
                color: color
            ), at: 0)
        }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(highlights) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
