import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Translation choice

enum WidgetTranslation: String, AppEnum {
    case rv1960, cornilescu

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Translation"
    static var caseDisplayRepresentations: [WidgetTranslation: DisplayRepresentation] = [
        .rv1960:     "Reina-Valera 1960 (Español)",
        .cornilescu: "Cornilescu (Română)"
    ]
}

struct VerseWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Biblia Real"
    static var description = IntentDescription("Verse of the day")

    @Parameter(title: "Translation", default: WidgetTranslation.rv1960)
    var translation: WidgetTranslation
}

// MARK: - Timeline

struct VerseEntry: TimelineEntry {
    let date: Date
    let verse: WidgetVerse?
    let translation: WidgetTranslation
}

struct VerseProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now,
                   verse: WidgetVerse(bookName: "Juan", chapter: 3, verse: 16,
                                      text: "Porque de tal manera amó Dios al mundo, que ha dado a su Hijo unigénito."),
                   translation: .rv1960)
    }

    func snapshot(for configuration: VerseWidgetIntent, in context: Context) async -> VerseEntry {
        makeEntry(for: configuration)
    }

    func timeline(for configuration: VerseWidgetIntent, in context: Context) async -> Timeline<VerseEntry> {
        let entry = makeEntry(for: configuration)
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
        return Timeline(entries: [entry], policy: .after(midnight))
    }

    private func makeEntry(for config: VerseWidgetIntent) -> VerseEntry {
        VerseEntry(
            date: .now,
            verse: WidgetDatabase.shared.verseOfDay(translation: config.translation.rawValue),
            translation: config.translation
        )
    }
}

// MARK: - View

struct VerseWidgetView: View {
    let entry: VerseEntry
    @Environment(\.widgetFamily) private var family

    private var label: String {
        entry.translation == .rv1960 ? "VERSÍCULO DEL DÍA" : "VERSETUL ZILEI"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.accentColor)
                Text(label)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .kerning(0.5)
            }

            if let v = entry.verse {
                Text(verbatim: "\u{201C}\(v.text)\u{201D}")
                    .font(.system(size: family == .systemSmall ? 13 : 15, design: .serif))
                    .italic()
                    .foregroundStyle(.primary)
                    .lineLimit(family == .systemSmall ? 4 : 7)
                    .fixedSize(horizontal: false, vertical: false)

                Spacer(minLength: 0)

                Text(verbatim: "\(v.bookName) \(v.chapter):\(v.verse)")
                    .font(.caption.bold())
                    .foregroundStyle(Color.accentColor)
            } else {
                Spacer(minLength: 0)
                Text("—")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget + Bundle

struct BibliaRealWidget: Widget {
    let kind = "BibliaRealWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: VerseWidgetIntent.self,
            provider: VerseProvider()
        ) { entry in
            VerseWidgetView(entry: entry)
        }
        .configurationDisplayName("Versículo del Día")
        .description("Un versículo diferente cada día.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct BibliaRealWidgetBundle: WidgetBundle {
    var body: some Widget {
        BibliaRealWidget()
    }
}
