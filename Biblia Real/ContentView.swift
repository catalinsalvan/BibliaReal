import SwiftUI

private struct ChapterSlide: ViewModifier {
    let offsetX: CGFloat
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(x: offsetX)
            .opacity(opacity)
    }
}

struct ContentView: View {
    var initialVerse: Int? = nil

    @AppStorage("translation") private var selectedTranslation: Translation = .rv1960
    @AppStorage("fontSize")      private var fontSize: Double = 18
    @AppStorage("lineSpacing")   private var lineSpacing: Double = 12
    @AppStorage("theme") private var theme: ReadingTheme = .white
    @AppStorage("bookIdx") private var bookIdx: Int = 0
    @AppStorage("chapterIdx") private var chapterIdx: Int = 0
    @State private var books: [Book] = []
    @State private var currentChapter: Chapter?
    @State private var showSettings = false
    @State private var showBookPicker = false
    @State private var showChapterPicker = false
    @State private var showSearch = false
    @State private var showBookmarks = false
    @State private var pendingNavigation: (bookId: Int, chapter: Int)? = nil
    @State private var navDirection = 0
    @State private var highlightedVerse: Int? = nil
    @ObservedObject private var bookmarkStore = BookmarkStore.shared
    @Environment(\.dismiss) private var dismiss

    private var chapterTransition: AnyTransition {
        let sign: CGFloat = navDirection >= 0 ? 1 : -1
        return .asymmetric(
            insertion: .modifier(
                active:   ChapterSlide(offsetX:  320 * sign, opacity: 0),
                identity: ChapterSlide(offsetX:  0,          opacity: 1)
            ),
            removal: .modifier(
                active:   ChapterSlide(offsetX: -110 * sign, opacity: 0),
                identity: ChapterSlide(offsetX:  0,          opacity: 1)
            )
        )
    }

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

            ZStack {
                if let book = currentBook, let chapter = currentChapter {
                    ReadingView(
                        book: book,
                        chapter: chapter,
                        selectedTranslation: selectedTranslation,
                        onSwipeLeft: { goNext() },
                        onSwipeRight: { goPrev() },
                        highlightVerse: highlightedVerse
                    )
                    .id("\(book.id)_\(chapter.number)_\(selectedTranslation.rawValue)_\(Int(fontSize))_\(Int(lineSpacing))")
                    .transition(chapterTransition)
                } else {
                    ContentUnavailableView(selectedTranslation.noContentLabel, systemImage: "book.closed")
                }
            }
            .clipped()
        }
        .ignoresSafeArea(edges: [.horizontal, .bottom])
        .background(theme.background, ignoresSafeAreaEdges: .top)
        .onAppear {
            loadBooks()
            if let v = initialVerse { highlightedVerse = v }
        }
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
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                }
                .glassEffect(in: Capsule())

                Button {
                    showBookPicker = true
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
                .popover(isPresented: $showBookPicker, arrowEdge: .top) {
                    bookPicker
                }

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
                            highlightedVerse = result.verse
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

    // MARK: - Book picker

    private var bookPicker: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(books.indices, id: \.self) { i in
                    Button {
                        bookIdx = i
                        chapterIdx = 0
                        showBookPicker = false
                    } label: {
                        HStack {
                            Text(books[i].name)
                                .font(.system(size: 15, weight: bookIdx == i ? .semibold : .regular))
                                .foregroundStyle(bookIdx == i ? Color.accentColor : Color.primary)
                            Spacer()
                            if bookIdx == i {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if i < books.count - 1 { Divider().padding(.leading, 16) }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(width: 260)
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
        var newBookIdx = bookIdx
        var newChapterIdx = chapterIdx
        if chapterIdx < book.chapterCount - 1 {
            newChapterIdx += 1
        } else if bookIdx < books.count - 1 {
            newBookIdx += 1
            newChapterIdx = 0
        } else { return }
        animateToChapter(bookIdx: newBookIdx, chapterIdx: newChapterIdx, direction: 1)
    }

    private func goPrev() {
        var newBookIdx = bookIdx
        var newChapterIdx = chapterIdx
        if chapterIdx > 0 {
            newChapterIdx -= 1
        } else if bookIdx > 0 {
            newBookIdx -= 1
            newChapterIdx = books[newBookIdx].chapterCount - 1
        } else { return }
        animateToChapter(bookIdx: newBookIdx, chapterIdx: newChapterIdx, direction: -1)
    }

    private func animateToChapter(bookIdx newBookIdx: Int, chapterIdx newChapterIdx: Int, direction: Int) {
        let newBook = books[newBookIdx]
        let newChapter = BibleDatabase.shared.chapter(
            translation: selectedTranslation,
            bookId: newBook.id,
            number: newChapterIdx + 1
        )
        navDirection = direction
        highlightedVerse = nil
        withAnimation(.spring(response: 0.44, dampingFraction: 0.60)) {
            bookIdx = newBookIdx
            chapterIdx = newChapterIdx
            currentChapter = newChapter
        }
    }
}
