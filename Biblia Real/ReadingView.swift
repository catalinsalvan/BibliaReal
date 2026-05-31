import SwiftUI
import PencilKit

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// Walks the superview chain to find the UIScrollView that backs a SwiftUI ScrollView.
// Used to programmatically scroll the text column when the margin canvas is scrolled.
private struct ScrollViewAnchor: UIViewRepresentable {
    var onFound: (UIScrollView) -> Void

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.backgroundColor = .clear
        v.isHidden = true
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Walk up once the view is in the hierarchy.
        DispatchQueue.main.async {
            var current: UIView? = uiView.superview
            while let c = current {
                if let sv = c as? UIScrollView {
                    onFound(sv)
                    return
                }
                current = c.superview
            }
        }
    }
}

private struct VersePosKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
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
    @AppStorage("pencilHighlightColor") private var pencilHighlightColorRaw: String = HighlightColor.yellow.rawValue
    @State private var toolPicker = PKToolPicker()
    @State private var marginDrawing = PKDrawing()

    private var pencilHighlightColor: HighlightColor {
        HighlightColor(rawValue: pencilHighlightColorRaw) ?? .yellow
    }
    @State private var contentHeight: CGFloat = 0
    @State private var verseFrames: [Int: CGRect] = [:]
    @State private var textScrollOffset: CGFloat = 0
    @State private var textScrollView: UIScrollView? = nil
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
            let isPortrait  = geo.size.height > geo.size.width
            let marginWidth = isPortrait ? 0 : geo.size.width * marginRatio - 1
            let textWidth   = isPortrait ? geo.size.width : geo.size.width * (1 - marginRatio)
            let canvasHeight = max(contentHeight, geo.size.height)

            HStack(spacing: 0) {

                // ── Text column — unchanged ──────────────────────────
                ScrollViewReader { proxy in
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            ScrollViewAnchor { sv in textScrollView = sv }
                                .frame(height: 0)
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
                                    GeometryReader { gp in
                                        Color.clear.preference(
                                            key: ContentHeightKey.self,
                                            value: gp.size.height
                                        )
                                    }
                                )

                                PencilHighlightDetector(verseFrames: verseFrames) { num in
                                    if let v = chapter.verses.first(where: { $0.number == num }) {
                                        applyPencilHighlight(to: v)
                                    }
                                }
                                .frame(height: canvasHeight)
                            }
                            .coordinateSpace(name: "textColumn")
                            .frame(minHeight: canvasHeight)
                        }
                    }
                    .background(theme.background)
                    .frame(width: textWidth)
                    .onScrollGeometryChange(for: CGFloat.self, of: { $0.contentOffset.y }) { _, y in
                        textScrollOffset = max(0, y)
                    }
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

                // ── Margin (landscape only) ──────────────────────────
                // Canvas viewport is driven by textScrollOffset — no SwiftUI
                // ScrollView wrapper needed (that caused pencil-hover glitches).
                if !isPortrait {
                    Rectangle()
                        .fill(theme.separator)
                        .frame(width: 1)

                    PencilCanvasView(
                        drawing: $marginDrawing,
                        backgroundColor: UIColor(theme.background),
                        toolPicker: toolPicker,
                        scrollContentHeight: canvasHeight,
                        syncedScrollOffset: textScrollOffset,
                        onMarginScrolled: { y in
                            textScrollView?.setContentOffset(
                                CGPoint(x: 0, y: max(0, y)), animated: false
                            )
                        },
                        onSwipeLeft: onSwipeLeft,
                        onSwipeRight: onSwipeRight
                    )
                    .frame(width: marginWidth, height: geo.size.height)
                }
            }
            .background(theme.background)
        }
        .ignoresSafeArea(edges: .bottom)
        .onPreferenceChange(ContentHeightKey.self) { h in contentHeight = h }
        .onPreferenceChange(VersePosKey.self)      { f in verseFrames  = f }
        .onChange(of: marginDrawing) { _, _ in saveAnnotations() }
    }

    // MARK: - Subviews

    private var chapterHeader: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(theme.separator)
                .frame(height: 0.5)
            Text("\(chapter.number)")
                .font(.system(size: fontSize * 2, weight: .regular, design: .serif))
                .foregroundStyle(theme.secondaryText)
                .fixedSize()
            Rectangle()
                .fill(theme.separator)
                .frame(height: 0.5)
        }
        .padding(.bottom, lineSpacing * 0.8)
    }

    // MARK: - Verse cell

    @ViewBuilder
    private func verseCell(_ verse: Verse) -> some View {
        let isHL = verse.number == highlightVerse
        let storedColor = highlightStore.color(
            translation: selectedTranslation,
            bookId: book.id,
            chapter: chapter.number,
            verse: verse.number
        )

        if isPoetryBook {
            poetryVerseText(verse)
                .lineSpacing(lineSpacing)
                .multilineTextAlignment(.center)
                .background(verseHighlightBG(isHL: isHL, storedColor: storedColor))
                .background(versePosBackground(verse))
                .id("verse_\(verse.number)")
                .contextMenu { verseMenuItems(verse: verse, storedColor: storedColor) }
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(verse.number)")
                    .font(readingFont.font(size: fontSize * 0.62))
                    .foregroundStyle(theme.secondaryText)
                    .frame(width: 30, alignment: .trailing)
                Text(verse.text)
                    .font(readingFont.font(size: fontSize))
                    .foregroundStyle(theme.text)
                    .lineSpacing(lineSpacing)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(verseHighlightBG(isHL: isHL, storedColor: storedColor))
            }
            .background(versePosBackground(verse))
            .id("verse_\(verse.number)")
            .contextMenu { verseMenuItems(verse: verse, storedColor: storedColor) }
        }
    }

    private func poetryVerseText(_ verse: Verse) -> Text {
        var num = AttributedString("\(verse.number)")
        num.font            = readingFont.font(size: fontSize * 0.60)
        num.foregroundColor = theme.secondaryText
        num.baselineOffset  = fontSize * 0.28
        var body = AttributedString(verse.text)
        body.font            = readingFont.font(size: fontSize)
        body.foregroundColor = theme.text
        return Text(num + body)
    }

    private func verseHighlightBG(isHL: Bool, storedColor: HighlightColor?) -> some View {
        ZStack {
            if let c = storedColor {
                RoundedRectangle(cornerRadius: 3).fill(c.color.opacity(0.35))
            }
            if isHL {
                RoundedRectangle(cornerRadius: 3).fill(Color.yellow.opacity(highlightOpacity * 0.42))
            }
        }
    }

    // Reports this verse's frame into the "textColumn" coordinate space so the
    // single PencilHighlightDetector overlay can map touch positions to verses.
    private func versePosBackground(_ verse: Verse) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: VersePosKey.self,
                value: [verse.number: proxy.frame(in: .named("textColumn"))]
            )
        }
    }

    private func applyPencilHighlight(to verse: Verse) {
        highlightStore.set(
            pencilHighlightColor,
            translation: selectedTranslation,
            bookId: book.id,
            chapter: chapter.number,
            verse: verse.number
        )
    }

    @ViewBuilder
    private func verseMenuItems(verse: Verse, storedColor: HighlightColor?) -> some View {
        ForEach(HighlightColor.allCases, id: \.self) { hc in
            Button {
                highlightStore.set(
                    hc,
                    translation: selectedTranslation,
                    bookId: book.id,
                    chapter: chapter.number,
                    verse: verse.number
                )
                pencilHighlightColorRaw = hc.rawValue   // pencil adopts this colour
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
        marginDrawing = AnnotationStore.shared.loadMargin(key: annotationKey)
    }

    private func saveAnnotations() {
        AnnotationStore.shared.save(key: annotationKey, margin: marginDrawing)
    }
}
