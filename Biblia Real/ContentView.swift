import SwiftUI

struct ContentView: View {
    @AppStorage("translation") private var selectedTranslation: Translation = .rv1960
    @AppStorage("fontSize") private var fontSize: Double = 18
    @AppStorage("theme") private var theme: ReadingTheme = .white
    @AppStorage("bookIdx") private var bookIdx: Int = 0
    @AppStorage("chapterIdx") private var chapterIdx: Int = 0
    @State private var books: [Book] = []
    @State private var currentChapter: Chapter?
    @State private var showSettings = false
    @State private var showChapterPicker = false
    @State private var showSearch = false
    @State private var showBookmarks = false
    @State private var pendingNavigation: (bookId: Int, chapter: Int)? = nil
    @ObservedObject private var bookmarkStore = BookmarkStore.shared

    private var currentBook: Book? { books.isEmpty ? nil : books[bookIdx] }

    private var currentBookIsBookmarked: Bool {
        guard let book = currentBook, let chapter = currentChapter else { return false }
        return bookmarkStore.isBookmarked(translation: selectedTranslation, bookId: book.id, chapter: chapter.number)
    }

    private var hasNext: Bool {
        guard let book = currentBook else { return false }
        return chapterIdx < book.chapterCount - 1 || bookIdx < books.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            if let book = currentBook, let chapter = currentChapter {
                ReadingView(
                    book: book,
                    chapter: chapter,
                    selectedTranslation: selectedTranslation
                )
                .id("\(book.id)_\(chapter.number)_\(selectedTranslation.rawValue)_\(Int(fontSize))_\(Int(lineSpacing))")
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            guard abs(horizontal) > abs(vertical) else { return }
                            if horizontal < 0 { goNext() }
                            else { goPrev() }
                        }
                )
            } else {
                ContentUnavailableView("Sin contenido", systemImage: "book.closed")
            }
        }
        .ignoresSafeArea(edges: [.horizontal, .bottom])
        .background(theme.background, ignoresSafeAreaEdges: .top)
        .onAppear { loadBooks() }
        .onChange(of: selectedTranslation) { _, _ in
            if pendingNavigation == nil {
                bookIdx = 0
                chapterIdx = 0
            }
            loadBooks()
        }
        .onChange(of: bookIdx) { _, _ in loadChapter() }
        .onChange(of: chapterIdx) { _, _ in loadChapter() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            // ── Navigation pills ──────────────────────────────────
            HStack(spacing: 10) {
                Menu {
                    ForEach(books.indices, id: \.self) { i in
                        Button(books[i].name) {
                            bookIdx = i
                            chapterIdx = 0
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(currentBook?.name ?? "—")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                }
                .glassEffect(in: Capsule())

                Button {
                    showChapterPicker = true
                } label: {
                    HStack(spacing: 4) {
                        Text(currentChapter.map { "Cap. \($0.number)" } ?? "—")
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 14)
                }
                .glassEffect(in: Capsule())
                .popover(isPresented: $showChapterPicker, arrowEdge: .top) {
                    chapterGrid
                }
            }

            Spacer()

            // ── Actions pill ──────────────────────────────────────
            HStack(spacing: 0) {
                Button {
                    showBookmarks = true
                } label: {
                    Image(systemName: currentBookIsBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16))
                        .foregroundStyle(currentBookIsBookmarked ? Color.accentColor : .secondary)
                        .padding(10)
                }
                .sheet(isPresented: $showBookmarks) {
                    if let book = currentBook, let chapter = currentChapter {
                        BookmarksView(
                            currentTranslation: selectedTranslation,
                            currentBookId: book.id,
                            currentBookName: book.name,
                            currentChapter: chapter.number
                        ) { bookmark in
                            navigateTo(bookmark)
                        }
                        .presentationDetents([.medium, .large])
                    }
                }

                Button {
                    showSearch = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .padding(10)
                }
                .sheet(isPresented: $showSearch) {
                    SearchView(translation: selectedTranslation, books: books) { result in
                        if let idx = books.firstIndex(where: { $0.id == result.bookId }) {
                            bookIdx = idx
                            chapterIdx = result.chapter - 1
                        }
                    }
                    .presentationDetents([.medium, .large])
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .padding(10)
                }
                .popover(isPresented: $showSettings, arrowEdge: .top) {
                    SettingsView(selectedTranslation: $selectedTranslation, isPresented: $showSettings)
                }
            }
            .glassEffect(in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Chapter grid

    private var chapterGrid: some View {
        let columns = Array(repeating: GridItem(.fixed(48)), count: 5)
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                if let book = currentBook {
                    ForEach(0..<book.chapterCount, id: \.self) { i in
                        Button("\(i + 1)") {
                            chapterIdx = i
                            showChapterPicker = false
                        }
                        .frame(width: 44, height: 44)
                        .background(
                            chapterIdx == i
                                ? Color.accentColor
                                : Color(.secondarySystemBackground)
                        )
                        .foregroundStyle(chapterIdx == i ? Color.white : Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .font(.system(size: 15, weight: chapterIdx == i ? .semibold : .regular))
                    }
                }
            }
            .padding(16)
        }
        .frame(width: 296)
        .frame(maxHeight: 400)
        .presentationCompactAdaptation(.popover)
    }

    // MARK: - Data loading

    private func loadBooks() {
        books = BibleDatabase.shared.books(for: selectedTranslation)
        if let pending = pendingNavigation {
            bookIdx = books.firstIndex(where: { $0.id == pending.bookId }) ?? 0
            chapterIdx = pending.chapter - 1
            pendingNavigation = nil
        } else {
            bookIdx = min(bookIdx, max(0, books.count - 1))
        }
        loadChapter()
    }

    private func navigateTo(_ bookmark: Bookmark) {
        if bookmark.translation == selectedTranslation.rawValue {
            if let idx = books.firstIndex(where: { $0.id == bookmark.bookId }) {
                bookIdx = idx
                chapterIdx = bookmark.chapter - 1
            }
        } else if let translation = Translation(rawValue: bookmark.translation) {
            pendingNavigation = (bookId: bookmark.bookId, chapter: bookmark.chapter)
            selectedTranslation = translation
        }
    }

    private func loadChapter() {
        guard let book = currentBook else { currentChapter = nil; return }
        currentChapter = BibleDatabase.shared.chapter(
            translation: selectedTranslation,
            bookId: book.id,
            number: chapterIdx + 1
        )
    }

    // MARK: - Navigation

    private func goNext() {
        guard let book = currentBook else { return }
        if chapterIdx < book.chapterCount - 1 {
            chapterIdx += 1
        } else if bookIdx < books.count - 1 {
            bookIdx += 1
            chapterIdx = 0
        }
    }

    private func goPrev() {
        if chapterIdx > 0 {
            chapterIdx -= 1
        } else if bookIdx > 0 {
            bookIdx -= 1
            chapterIdx = books[bookIdx].chapterCount - 1
        }
    }
}
