import SwiftUI

private struct ReferenceMatch {
    let book: Book
    let chapter: Int
    let verse: Int?

    var label: String {
        verse.map { "\(book.name) \(chapter):\($0)" } ?? "\(book.name) \(chapter)"
    }
}

struct SearchView: View {
    let translation: Translation
    let books: [Book]
    let onSelect: (SearchResult) -> Void

    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var referenceMatch: ReferenceMatch? = nil
    @State private var searchTask: Task<Void, Never>?
    @State private var isSearching = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    ContentUnavailableView("Buscar versículos", systemImage: "magnifyingglass",
                        description: Text("Escribe una referencia (Juan 3:16) o una palabra"))
                } else {
                    if let ref = referenceMatch {
                        Section("Referencia") {
                            Button {
                                onSelect(SearchResult(
                                    bookId: ref.book.id,
                                    bookName: ref.book.name,
                                    chapter: ref.chapter,
                                    verse: ref.verse ?? 1,
                                    text: ""
                                ))
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(ref.label)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                        Text("Ir al capítulo")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if isSearching {
                        HStack { Spacer(); ProgressView(); Spacer() }
                            .listRowSeparator(.hidden)
                    } else if results.isEmpty && referenceMatch == nil {
                        ContentUnavailableView.search(text: query)
                    } else if !results.isEmpty {
                        Section(results.count == 200
                                ? "Primeros 200 resultados"
                                : "\(results.count) resultado\(results.count == 1 ? "" : "s")") {
                            ForEach(results) { result in
                                Button {
                                    onSelect(result)
                                    dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(result.reference)
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(Color.accentColor)
                                        Text(highlighted(result.text, query: query))
                                            .font(.system(size: 15))
                                            .foregroundStyle(.primary)
                                            .lineLimit(3)
                                    }
                                    .padding(.vertical, 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Buscar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .searchable(text: $query,
                        placement: .navigationBarDrawer(displayMode: .always),
                        prompt: "Referencia o palabra...")
            .onChange(of: query) { _, newValue in
                referenceMatch = parseReference(newValue)
                searchTask?.cancel()
                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else {
                    results = []
                    isSearching = false
                    return
                }
                isSearching = true
                searchTask = Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    let found = BibleDatabase.shared.search(translation: translation, query: trimmed)
                    await MainActor.run {
                        results = found
                        isSearching = false
                    }
                }
            }
        }
    }

    // MARK: - Reference parsing

    private func parseReference(_ query: String) -> ReferenceMatch? {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard let regex = try? NSRegularExpression(pattern: #"^(.+?)\s+(\d+)(?::(\d+))?$"#),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let bookRange = Range(match.range(at: 1), in: trimmed),
              let chapterRange = Range(match.range(at: 2), in: trimmed) else { return nil }

        let bookQuery = String(trimmed[bookRange])
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        let chapter = Int(String(trimmed[chapterRange]))!
        let verse: Int? = match.range(at: 3).location != NSNotFound
            ? Range(match.range(at: 3), in: trimmed).flatMap { Int(String(trimmed[$0])) }
            : nil

        let matched = books.first { book in
            let normalized = book.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            return normalized.hasPrefix(bookQuery)
        }

        guard let book = matched, chapter >= 1, chapter <= book.chapterCount else { return nil }
        return ReferenceMatch(book: book, chapter: chapter, verse: verse)
    }

    // MARK: - Highlight

    private func highlighted(_ text: String, query: String) -> AttributedString {
        var attributed = AttributedString(text)
        let lower = text.lowercased()
        let queryLower = query.lowercased()
        var searchStart = lower.startIndex
        while let range = lower.range(of: queryLower, range: searchStart..<lower.endIndex) {
            if let lo = AttributedString.Index(range.lowerBound, within: attributed),
               let hi = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[lo..<hi].backgroundColor = .yellow
                attributed[lo..<hi].foregroundColor = .black
            }
            searchStart = range.upperBound
        }
        return attributed
    }
}
