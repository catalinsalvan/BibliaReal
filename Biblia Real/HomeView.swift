import SwiftUI

private enum HomeDestination: Hashable {
    case reading(initialVerse: Int?)
}

struct HomeView: View {
    @AppStorage("translation") private var selectedTranslation: Translation = .rv1960
    @AppStorage("bookIdx")     private var bookIdx: Int = 0
    @AppStorage("chapterIdx")  private var chapterIdx: Int = 0
    @AppStorage("theme")       private var theme: ReadingTheme = .white
    @AppStorage("planDay")     private var planDay: Int = 1

    @State private var path: [HomeDestination] = []
    @State private var books: [Book] = []
    @State private var lastBookName = ""
    @State private var verseOfDay: (bookId: Int, chapter: Int, verse: Int, text: String, bookName: String)?
    @State private var showPlan = false
    @State private var pendingPassage: (bookId: Int, chapter: Int)?

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        branding
                            .padding(.top, 60)
                            .padding(.bottom, 36)

                        VStack(spacing: 14) {
                            verseOfDayCard
                            continueCard
                            planCard
                            randomCard
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 60)
                    }
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationDestination(for: HomeDestination.self) { dest in
                switch dest {
                case .reading(let verse):
                    ContentView(initialVerse: verse)
                        .toolbar(.hidden, for: .navigationBar)
                }
            }
        }
        .sheet(isPresented: $showPlan, onDismiss: handlePlanDismiss) {
            PlanView(books: books, translation: selectedTranslation) { bookId, chapter in
                pendingPassage = (bookId, chapter)
                showPlan = false
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear { reload() }
        .onChange(of: selectedTranslation) { _, _ in reload() }
        .onChange(of: bookIdx) { _, _ in loadLastBook() }
    }

    // MARK: - Subviews

    private var branding: some View {
        VStack(spacing: 18) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)
            Text("Biblia Real")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(theme.text)
            Text(selectedTranslation.appSubtitle)
                .font(.title3)
                .foregroundStyle(theme.secondaryText)
        }
    }

    private var verseOfDayCard: some View {
        Button { navigateToVerseOfDay() } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.accentColor)
                    Text(selectedTranslation.verseDayLabel)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.secondaryText)
                        .textCase(.uppercase)
                    Spacer()
                }

                if let v = verseOfDay {
                    Text(verbatim: "\u{201C}\(v.text)\u{201D}")
                        .font(.system(size: 15, design: .serif))
                        .italic()
                        .foregroundStyle(theme.text)
                        .lineLimit(5)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(verbatim: "\(v.bookName) \(v.chapter):\(v.verse)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text(verbatim: "…")
                        .foregroundStyle(theme.secondaryText)
                        .frame(height: 60)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }

    private var continueCard: some View {
        Button { path.append(.reading(initialVerse: nil)) } label: {
            HStack(spacing: 16) {
                Image(systemName: "book.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedTranslation.continueReadingLabel)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                    Text(lastBookName.isEmpty ? "…" : "\(lastBookName) · Cap. \(chapterIdx + 1)")
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.text)
                    Text(selectedTranslation.displayName)
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }

    private var planCard: some View {
        Button { showPlan = true } label: {
            HStack(spacing: 16) {
                Image(systemName: "checklist")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedTranslation.plansLabel)
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                    Text(selectedTranslation.planTitle)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.text)
                    Text("\(selectedTranslation.planDayOf) \(min(planDay, 260)) \(selectedTranslation.planOf260)")
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }

    private var randomCard: some View {
        Button { navigateRandom() } label: {
            HStack(spacing: 16) {
                Image(systemName: "shuffle")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28)
                Text(selectedTranslation.randomLabel)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Navigation

    private func navigateToVerseOfDay() {
        guard let v = verseOfDay else {
            path.append(.reading(initialVerse: nil))
            return
        }
        if let idx = books.firstIndex(where: { $0.id == v.bookId }) {
            bookIdx = idx
            chapterIdx = v.chapter - 1
        }
        path.append(.reading(initialVerse: v.verse))
    }

    private func navigateRandom() {
        guard !books.isEmpty else { return }
        let rBook = Int.random(in: 0..<books.count)
        let rChapter = Int.random(in: 0..<books[rBook].chapterCount)
        bookIdx = rBook
        chapterIdx = rChapter
        path.append(.reading(initialVerse: nil))
    }

    private func handlePlanDismiss() {
        guard let passage = pendingPassage else { return }
        if let idx = books.firstIndex(where: { $0.id == passage.bookId }) {
            bookIdx = idx
            chapterIdx = passage.chapter - 1
        }
        pendingPassage = nil
        path.append(.reading(initialVerse: nil))
    }

    // MARK: - Data

    private func reload() {
        books = BibleDatabase.shared.books(for: selectedTranslation)
        loadLastBook()
        loadVerseOfDay()
    }

    private func loadLastBook() {
        lastBookName = books.indices.contains(bookIdx) ? books[bookIdx].name : ""
    }

    private func loadVerseOfDay() {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let day  = cal.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let seed = year * 400 + day
        guard let v = BibleDatabase.shared.verseOfDay(translation: selectedTranslation, seed: seed) else { return }
        let name = books.first(where: { $0.id == v.bookId })?.name ?? ""
        verseOfDay = (v.bookId, v.chapter, v.verse, v.text, name)
    }

}
