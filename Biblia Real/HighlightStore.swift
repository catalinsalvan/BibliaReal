import SwiftUI
import Combine

enum HighlightColor: String, CaseIterable, Codable {
    case yellow, green, pink, blue, purple

    var color: Color {
        switch self {
        case .yellow: return Color(red: 1.00, green: 0.80, blue: 0.20) // amber / honey
        case .green:  return Color(red: 0.35, green: 0.80, blue: 0.60) // mint / sage
        case .pink:   return Color(red: 1.00, green: 0.42, blue: 0.56) // rose / coral
        case .blue:   return Color(red: 0.38, green: 0.60, blue: 0.98) // periwinkle sky
        case .purple: return Color(red: 0.72, green: 0.52, blue: 0.98) // soft lavender
        }
    }

    func label(for translation: Translation) -> String {
        let ro = translation == .cornilescu
        switch self {
        case .yellow: return ro ? "Chihlimbar" : "Ámbar"
        case .green:  return ro ? "Mentă"      : "Menta"
        case .pink:   return ro ? "Trandafiriu" : "Rosa"
        case .blue:   return ro ? "Azuriu"     : "Celeste"
        case .purple: return ro ? "Lavandă"    : "Lavanda"
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
