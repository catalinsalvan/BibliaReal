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
    @State private var dragOffset: CGFloat = 0
    @State private var hapticTrigger = false
    @State private var swipeThresholdReached = false
    @ObservedObject private var bookmarkStore = BookmarkStore.shared
    @Environment(\.horizontalSizeClass) private var hSizeClass

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
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
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
                    .offset(x: dragOffset)
                } else {
                    ContentUnavailableView(selectedTranslation.noContentLabel, systemImage: "book.closed")
                }
            }
            .clipped()
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        guard isPortrait else { return }
                        let h = value.translation.width
                        let v = value.translation.height
                        guard abs(h) > abs(v) * 0.8 else { return }
                        if !swipeThresholdReached && abs(h) > 60 {
                            swipeThresholdReached = true
                            hapticTrigger.toggle()
                        }
                        let canLeft  = h < 0 && hasNext
                        let canRight = h > 0 && (bookIdx > 0 || chapterIdx > 0)
                        guard canLeft || canRight else { return }
                        dragOffset = h * 0.28
                    }
                    .onEnded { value in
                        guard isPortrait else { return }
                        swipeThresholdReached = false
                        let h = value.translation.width
                        let v = value.translation.height
                        if abs(h) > abs(v) * 2 && abs(h) > 60 {
                            if h < 0 { goNext() } else { goPrev() }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                dragOffset = 0
                            }
                        }
                    }
            )
            .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: hapticTrigger)
        }
        .ignoresSafeArea(edges: [.horizontal, .bottom])
        .background(theme.background, ignoresSafeAreaEdges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbarColorScheme(theme.isDark ? .dark : .light, for: .navigationBar)
        .toolbar {
            // ── Leading: prev / next chapter (iPad only — iPhone uses swipe) ──
            if hSizeClass != .compact {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button { goPrev() } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .disabled(bookIdx == 0 && chapterIdx == 0)

                    Button { goNext() } label: {
                        Image(systemName: "chevron.forward")
                    }
                    .disabled(!hasNext)
                }
            }

            // ── Center: tappable book · chapter ──────────────────
            ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Button { showBookPicker = true } label: {
                            HStack(spacing: 3) {
                                Text(currentBook?.name ?? "—")
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                        }
                        .popover(isPresented: $showBookPicker, arrowEdge: .top) { bookPicker }

                        Text("·").foregroundStyle(.tertiary)

                        Button { showChapterPicker = true } label: {
                            HStack(spacing: 3) {
                                Text(currentChapter.map { "\($0.number)" } ?? "—")
                                    .fontWeight(.semibold)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                        }
                        .popover(isPresented: $showChapterPicker, arrowEdge: .top) { chapterGrid }
                    }
                    .foregroundStyle(.primary)
                    .font(.system(size: 15))
                }

                // ── Trailing: bookmark ────────────────────────────────
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showBookmarks = true } label: {
                        Image(systemName: currentBookIsBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(currentBookIsBookmarked ? Color.accentColor : .secondary)
                    }
                    .sheet(isPresented: $showBookmarks) {
                        if let book = currentBook, let chapter = currentChapter {
                            BookmarksView(
                                currentTranslation: selectedTranslation,
                                currentBookId: book.id,
                                currentBookName: book.name,
                                currentChapter: chapter.number
                            ) { bookmark in navigateTo(bookmark) }
                            .presentationDetents([.medium, .large])
                        }
                    }
                }

                // ── Trailing: search ──────────────────────────────────
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSearch = true } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
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
                }

                // ── Trailing: settings ────────────────────────────────
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.secondary)
                    }
                    .popover(isPresented: $showSettings, arrowEdge: .top) {
                        SettingsView(selectedTranslation: $selectedTranslation,
                                     isPresented: $showSettings)
                    }
                }
        }
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
            dragOffset = 0
            bookIdx = newBookIdx
            chapterIdx = newChapterIdx
            currentChapter = newChapter
        }
    }
}
