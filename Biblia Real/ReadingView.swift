import SwiftUI
import PencilKit

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ReadingView: View {
    let book: Book
    let chapter: Chapter
    let selectedTranslation: Translation
    var onSwipeLeft: (() -> Void)? = nil
    var onSwipeRight: (() -> Void)? = nil
    var highlightVerse: Int? = nil

    @AppStorage("fontSize")    private var fontSize: Double = 18
    @AppStorage("lineSpacing") private var lineSpacing: Double = 12
    @AppStorage("theme")       private var theme: ReadingTheme = .white
    @AppStorage("readingFont") private var readingFont: ReadingFont = .inter
    @State private var toolPicker = PKToolPicker()
    @State private var overlayDrawing = PKDrawing()
    @State private var marginDrawing = PKDrawing()
    @State private var contentHeight: CGFloat = 0
    @State private var highlightOpacity: Double = 0
    @ObservedObject private var highlightStore = HighlightStore.shared

    private let marginRatio: CGFloat = 0.40

    private var annotationKey: String {
        "\(selectedTranslation.rawValue)_\(book.id)_\(chapter.number)_\(Int(fontSize))_\(Int(lineSpacing))"
    }

    private var isPoetryBook: Bool {
        let n = book.name
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        return n.hasPrefix("salm") || n.hasPrefix("psalm") ||
               n.hasPrefix("prover") ||
               n.hasPrefix("job")   || n.hasPrefix("iov") ||
               n.hasPrefix("cant")  ||
               n.hasPrefix("ecles") ||
               n.hasPrefix("lament")
    }

    var body: some View {
        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
            let marginWidth = isPortrait ? 0 : geo.size.width * marginRatio - 1
            let textWidth   = isPortrait ? geo.size.width : geo.size.width * (1 - marginRatio)

            HStack(spacing: 0) {

                // ── Text column ─────────────────────────────────────
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {

                            // Text + pencil canvas
                            ZStack(alignment: .topLeading) {
                                VStack(
                                    alignment: isPoetryBook ? .center : .leading,
                                    spacing: isPoetryBook ? lineSpacing * 2.4 : lineSpacing * 1.2
                                ) {
                                    chapterHeader
                                    ForEach(chapter.verses) { verse in
                                        verseCell(verse)
                                    }
                                }
                                .frame(maxWidth: .infinity,
                                       alignment: isPoetryBook ? .center : .leading)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 28)
                                .background(
                                    GeometryReader { proxy in
                                        Color.clear.preference(
                                            key: ContentHeightKey.self,
                                            value: proxy.size.height
                                        )
                                    }
                                )

                                if isPortrait {
                                    SwipeDetectorView(
                                        onSwipeLeft: onSwipeLeft,
                                        onSwipeRight: onSwipeRight
                                    )
                                    .frame(height: max(contentHeight, geo.size.height))
                                } else {
                                    PencilCanvasView(
                                        drawing: $overlayDrawing,
                                        toolPicker: toolPicker,
                                        onSwipeLeft: onSwipeLeft,
                                        onSwipeRight: onSwipeRight
                                    )
                                    .frame(height: max(contentHeight, geo.size.height))
                                }
                            }
                            .frame(minHeight: max(contentHeight, geo.size.height))

                            // Next-chapter arrow — sits below the canvas, always tappable
                            nextChapterButton
                        }
                    }
                    .background(theme.background)
                    .frame(width: textWidth)
                    .onAppear {
                        loadAnnotations()
                        if let verse = highlightVerse {
                            startHighlight(verse: verse, proxy: proxy)
                        }
                    }
                    .onChange(of: highlightVerse) { _, verse in
                        guard let verse else { return }
                        startHighlight(verse: verse, proxy: proxy)
                    }
                }

                // ── Margin (landscape only) ───────────────────────────
                if !isPortrait {
                    Rectangle()
                        .fill(theme.separator)
                        .frame(width: 1)

                    PencilCanvasView(
                        drawing: $marginDrawing,
                        backgroundColor: UIColor(theme.background),
                        toolPicker: toolPicker,
                        onSwipeLeft: onSwipeLeft,
                        onSwipeRight: onSwipeRight
                    )
                    .frame(width: marginWidth, height: geo.size.height)
                }
            }
            .background(theme.background)
        }
        .ignoresSafeArea(edges: .bottom)
        .onPreferenceChange(ContentHeightKey.self) { h in
            contentHeight = h
        }
        .onChange(of: overlayDrawing) { _, _ in saveAnnotations() }
        .onChange(of: marginDrawing)  { _, _ in saveAnnotations() }
    }

    // MARK: - Subviews

    private var chapterHeader: some View {
        Text("\(chapter.number)")
            .font(.system(size: fontSize * 3.2, weight: .bold, design: .serif))
            .foregroundStyle(theme.text.opacity(0.48))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, lineSpacing * 0.5)
    }

    private var nextChapterButton: some View {
        Button { onSwipeLeft?() } label: {
            HStack(spacing: 14) {
                Rectangle()
                    .fill(theme.separator)
                    .frame(height: 0.5)
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(theme.secondaryText.opacity(0.4))
                Rectangle()
                    .fill(theme.separator)
                    .frame(height: 0.5)
            }
            .padding(.horizontal, 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.top, 20)
        .padding(.bottom, 52)
    }

    // MARK: - Verse cell

    private func verseCell(_ verse: Verse) -> some View {
        var num = AttributedString("\(verse.number)")
        num.font            = readingFont.font(size: fontSize * 0.60)
        num.foregroundColor = theme.secondaryText
        num.baselineOffset  = fontSize * 0.28

        var body = AttributedString(verse.text)
        body.font            = readingFont.font(size: fontSize)
        body.foregroundColor = theme.text

        let isHL = verse.number == highlightVerse
        let storedColor = highlightStore.color(
            translation: selectedTranslation,
            bookId: book.id,
            chapter: chapter.number,
            verse: verse.number
        )
        return Text(num + body)
            .lineSpacing(lineSpacing)
            .multilineTextAlignment(isPoetryBook ? .center : .leading)
            .background(
                ZStack {
                    if let c = storedColor {
                        RoundedRectangle(cornerRadius: 3).fill(c.color.opacity(0.35))
                    }
                    if isHL {
                        RoundedRectangle(cornerRadius: 3).fill(Color.yellow.opacity(highlightOpacity * 0.42))
                    }
                }
            )
            .id("verse_\(verse.number)")
            .contextMenu {
                ForEach(HighlightColor.allCases, id: \.self) { hc in
                    Button {
                        highlightStore.set(
                            hc,
                            translation: selectedTranslation,
                            bookId: book.id,
                            chapter: chapter.number,
                            verse: verse.number
                        )
                    } label: {
                        Label(hc.label(for: selectedTranslation), systemImage: "circle.fill")
                    }
                    .tint(hc.color)
                }
                if storedColor != nil {
                    Button(role: .destructive) {
                        highlightStore.set(
                            nil,
                            translation: selectedTranslation,
                            bookId: book.id,
                            chapter: chapter.number,
                            verse: verse.number
                        )
                    } label: {
                        Label(selectedTranslation.highlightRemove, systemImage: "xmark.circle")
                    }
                }
            }
    }

    // MARK: - Highlight

    private func startHighlight(verse: Int, proxy: ScrollViewProxy) {
        highlightOpacity = 1.0
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeInOut(duration: 0.3)) {
                proxy.scrollTo("verse_\(verse)", anchor: .center)
            }
            try? await Task.sleep(for: .milliseconds(1000))
            withAnimation(.easeOut(duration: 1.6)) {
                highlightOpacity = 0
            }
        }
    }

    // MARK: - Annotations

    private func loadAnnotations() {
        let saved = AnnotationStore.shared.load(key: annotationKey)
        overlayDrawing = saved.overlay
        marginDrawing  = saved.margin
    }

    private func saveAnnotations() {
        AnnotationStore.shared.save(
            key: annotationKey,
            overlay: overlayDrawing,
            margin: marginDrawing
        )
    }
}
