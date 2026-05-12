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

    @AppStorage("fontSize")    private var fontSize: Double = 18
    @AppStorage("lineSpacing") private var lineSpacing: Double = 12
    @AppStorage("theme")       private var theme: ReadingTheme = .white
    @AppStorage("readingFont") private var readingFont: ReadingFont = .inter
    @State private var toolPicker = PKToolPicker()
    @State private var overlayDrawing = PKDrawing()
    @State private var marginDrawing = PKDrawing()
    @State private var contentHeight: CGFloat = 0

    private let marginRatio: CGFloat = 0.40

    private var annotationKey: String {
        "\(selectedTranslation.rawValue)_\(book.id)_\(chapter.number)_\(Int(fontSize))_\(Int(lineSpacing))"
    }

    var body: some View {

        GeometryReader { geo in
            let isPortrait = geo.size.height > geo.size.width
            let marginWidth = isPortrait ? 0 : geo.size.width * marginRatio - 1
            let textWidth   = isPortrait ? geo.size.width : geo.size.width * (1 - marginRatio)

            HStack(spacing: 0) {

                // ── Text column ─────────────────────────────────────
                ScrollView(.vertical) {
                    ZStack(alignment: .topLeading) {
                        VStack(alignment: .leading, spacing: lineSpacing * 1.2) {
                            ForEach(chapter.verses) { verse in
                                verseCell(verse)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 28)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ContentHeightKey.self,
                                    value: proxy.size.height
                                )
                            }
                        )

                        PencilCanvasView(drawing: $overlayDrawing, toolPicker: toolPicker)
                            .frame(height: max(contentHeight, geo.size.height))
                    }
                    .frame(minHeight: max(contentHeight, geo.size.height))
                }
                .background(theme.background)
                .frame(width: textWidth)

                // ── Margin (landscape only) ───────────────────────────
                if !isPortrait {
                    Rectangle()
                        .fill(theme.separator)
                        .frame(width: 1)

                    PencilCanvasView(
                        drawing: $marginDrawing,
                        backgroundColor: UIColor(theme.background),
                        toolPicker: toolPicker
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
        .onAppear(perform: loadAnnotations)
        .onChange(of: overlayDrawing) { _, _ in saveAnnotations() }
        .onChange(of: marginDrawing)  { _, _ in saveAnnotations() }
    }

    private func verseCell(_ verse: Verse) -> some View {
        (Text("\(verse.number) ")
            .font(readingFont.font(size: fontSize * 0.62))
            .foregroundColor(theme.secondaryText)
        + Text(verse.text)
            .font(readingFont.font(size: fontSize))
            .foregroundColor(theme.text))
        .lineSpacing(lineSpacing)
    }

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
