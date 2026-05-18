import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct WidgetVerse {
    let bookName: String
    let chapter: Int
    let verse: Int
    let text: String
}

final class WidgetDatabase {
    static let shared = WidgetDatabase()
    private var db: OpaquePointer?

    private init() {
        guard let url = Bundle.main.url(forResource: "bible", withExtension: "db") else { return }
        sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil)
    }

    func verseOfDay(translation: String) -> WidgetVerse? {
        guard let db else { return nil }

        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let day  = cal.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let seed = year * 400 + day

        var countStmt: OpaquePointer?
        sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM verses WHERE translation = ?", -1, &countStmt, nil)
        sqlite3_bind_text(countStmt, 1, translation, -1, SQLITE_TRANSIENT)
        sqlite3_step(countStmt)
        let total = Int(sqlite3_column_int(countStmt, 0))
        sqlite3_finalize(countStmt)
        guard total > 0 else { return nil }

        let offset = Int32(abs(seed) % total)
        let sql = """
            SELECT b.name, v.chapter, v.verse, v.text
            FROM verses v
            JOIN books b ON b.translation = v.translation AND b.id = v.book_id
            WHERE v.translation = ?
            ORDER BY v.book_id, v.chapter, v.verse
            LIMIT 1 OFFSET ?
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, translation, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 2, offset)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return WidgetVerse(
            bookName: String(cString: sqlite3_column_text(stmt, 0)),
            chapter:  Int(sqlite3_column_int(stmt, 1)),
            verse:    Int(sqlite3_column_int(stmt, 2)),
            text:     String(cString: sqlite3_column_text(stmt, 3))
        )
    }
}
