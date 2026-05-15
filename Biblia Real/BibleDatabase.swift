import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class BibleDatabase {
    static let shared = BibleDatabase()
    private var db: OpaquePointer?

    private init() {
        guard let url = Bundle.main.url(forResource: "bible", withExtension: "db") else {
            print("BibleDatabase: bible.db not found in bundle")
            return
        }
        if sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil) != SQLITE_OK {
            print("BibleDatabase: open failed")
        }
    }

    deinit { sqlite3_close(db) }

    func books(for translation: Translation) -> [Book] {
        guard let db else { return [] }
        let sql = "SELECT id, name, chapter_count FROM books WHERE translation = ? ORDER BY id"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, translation.rawValue, -1, SQLITE_TRANSIENT)
        var result: [Book] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            result.append(Book(
                id: Int(sqlite3_column_int(stmt, 0)),
                name: String(cString: sqlite3_column_text(stmt, 1)),
                chapterCount: Int(sqlite3_column_int(stmt, 2))
            ))
        }
        return result
    }

    func chapter(translation: Translation, bookId: Int, number: Int) -> Chapter? {
        guard let db else { return nil }
        let sql = "SELECT verse, text FROM verses WHERE translation = ? AND book_id = ? AND chapter = ? ORDER BY verse"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, translation.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 2, Int32(bookId))
        sqlite3_bind_int(stmt, 3, Int32(number))
        var verses: [Verse] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            verses.append(Verse(
                number: Int(sqlite3_column_int(stmt, 0)),
                text: String(cString: sqlite3_column_text(stmt, 1))
            ))
        }
        return verses.isEmpty ? nil : Chapter(number: number, verses: verses)
    }

    func verseOfDay(translation: Translation, seed: Int) -> (bookId: Int, chapter: Int, verse: Int, text: String)? {
        guard let db else { return nil }
        var countStmt: OpaquePointer?
        sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM verses WHERE translation = ?", -1, &countStmt, nil)
        sqlite3_bind_text(countStmt, 1, translation.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_step(countStmt)
        let total = Int(sqlite3_column_int(countStmt, 0))
        sqlite3_finalize(countStmt)
        guard total > 0 else { return nil }
        let offset = Int32(abs(seed) % total)
        let sql = "SELECT book_id, chapter, verse, text FROM verses WHERE translation = ? ORDER BY book_id, chapter, verse LIMIT 1 OFFSET ?"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, translation.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 2, offset)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }
        return (
            bookId:  Int(sqlite3_column_int(stmt, 0)),
            chapter: Int(sqlite3_column_int(stmt, 1)),
            verse:   Int(sqlite3_column_int(stmt, 2)),
            text:    String(cString: sqlite3_column_text(stmt, 3))
        )
    }

    func search(translation: Translation, query: String, limit: Int = 200) -> [SearchResult] {
        guard let db, !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let sql = """
            SELECT v.book_id, b.name, v.chapter, v.verse, v.text
            FROM verses v
            JOIN books b ON b.translation = v.translation AND b.id = v.book_id
            WHERE v.translation = ? AND v.text LIKE ? ESCAPE '\\'
            LIMIT ?
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        let pattern = "%\(query.replacingOccurrences(of: "%", with: "\\%").replacingOccurrences(of: "_", with: "\\_"))%"
        sqlite3_bind_text(stmt, 1, translation.rawValue, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, pattern, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 3, Int32(limit))
        var results: [SearchResult] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            results.append(SearchResult(
                bookId: Int(sqlite3_column_int(stmt, 0)),
                bookName: String(cString: sqlite3_column_text(stmt, 1)),
                chapter: Int(sqlite3_column_int(stmt, 2)),
                verse: Int(sqlite3_column_int(stmt, 3)),
                text: String(cString: sqlite3_column_text(stmt, 4))
            ))
        }
        return results
    }
}
