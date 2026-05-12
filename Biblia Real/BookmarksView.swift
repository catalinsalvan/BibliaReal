import SwiftUI

struct BookmarksView: View {
    let currentTranslation: Translation
    let currentBookId: Int
    let currentBookName: String
    let currentChapter: Int
    let onSelect: (Bookmark) -> Void

    @ObservedObject private var store = BookmarkStore.shared
    @Environment(\.dismiss) private var dismiss

    private var isCurrentBookmarked: Bool {
        store.isBookmarked(translation: currentTranslation, bookId: currentBookId, chapter: currentChapter)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        store.toggle(
                            translation: currentTranslation,
                            bookId: currentBookId,
                            bookName: currentBookName,
                            chapter: currentChapter
                        )
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: isCurrentBookmarked ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(Color.accentColor)
                                .frame(width: 20)
                            Text(isCurrentBookmarked ? "Quitar marcador" : "Añadir marcador")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("\(currentBookName) \(currentChapter)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                if !store.bookmarks.isEmpty {
                    Section("Guardados") {
                        ForEach(store.bookmarks) { bookmark in
                            Button {
                                onSelect(bookmark)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "bookmark.fill")
                                        .foregroundStyle(Color.accentColor)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bookmark.label)
                                            .foregroundStyle(.primary)
                                        if bookmark.translation != currentTranslation.rawValue,
                                           let t = Translation(rawValue: bookmark.translation) {
                                            Text(t.displayName)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(bookmark.addedAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { store.remove(at: $0) }
                    }
                } else {
                    ContentUnavailableView("Sin marcadores", systemImage: "bookmark",
                        description: Text("Toca \"Añadir marcador\" para guardar este capítulo"))
                }
            }
            .navigationTitle("Marcadores")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                if !store.bookmarks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
        }
    }
}
