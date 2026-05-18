import XCTest
@testable import Biblia_Real

final class BibleDatabaseTests: XCTestCase {
    let db = BibleDatabase.shared

    // MARK: - books()

    func testBooks_rv1960_returns66() {
        XCTAssertEqual(db.books(for: .rv1960).count, 66)
    }

    func testBooks_cornilescu_returns66() {
        XCTAssertEqual(db.books(for: .cornilescu).count, 66)
    }

    func testBooks_rv1960_firstBookIsGenesis() {
        let first = db.books(for: .rv1960).first
        XCTAssertNotNil(first)
        XCTAssertTrue(first!.name.lowercased().hasPrefix("gén") || first!.name.lowercased().hasPrefix("gen"),
                      "Expected Genesis, got \(first!.name)")
    }

    func testBooks_cornilescu_firstBookIsGenesis() {
        let first = db.books(for: .cornilescu).first
        XCTAssertNotNil(first)
        XCTAssertTrue(first!.name.lowercased().hasPrefix("gen"),
                      "Expected Geneza, got \(first!.name)")
    }

    func testBooks_lastBookIsRevelation() {
        let last = db.books(for: .rv1960).last
        XCTAssertNotNil(last)
        XCTAssertTrue(last!.name.lowercased().hasPrefix("apoc"),
                      "Expected Apocalipsis, got \(last!.name)")
    }

    func testBooks_idsAreUnique() {
        let ids = db.books(for: .rv1960).map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testBooks_allChapterCountsArePositive() {
        XCTAssertTrue(db.books(for: .rv1960).allSatisfy { $0.chapterCount > 0 })
        XCTAssertTrue(db.books(for: .cornilescu).allSatisfy { $0.chapterCount > 0 })
    }

    func testBooks_psalmsHas150Chapters() {
        let psalms = db.books(for: .rv1960).first {
            $0.name.lowercased().folding(options: .diacriticInsensitive, locale: .current).hasPrefix("salm")
        }
        XCTAssertNotNil(psalms)
        XCTAssertEqual(psalms!.chapterCount, 150)
    }

    func testBooks_revelationHas22Chapters() {
        let rev = db.books(for: .rv1960).last
        XCTAssertEqual(rev?.chapterCount, 22)
    }

    func testBooks_allNamesNonEmpty() {
        XCTAssertTrue(db.books(for: .rv1960).allSatisfy { !$0.name.isEmpty })
        XCTAssertTrue(db.books(for: .cornilescu).allSatisfy { !$0.name.isEmpty })
    }

    // MARK: - chapter()

    func testChapter_genesis1_returnsChapter() {
        let ch = db.chapter(translation: .rv1960, bookId: 1, number: 1)
        XCTAssertNotNil(ch)
        XCTAssertEqual(ch!.number, 1)
    }

    func testChapter_genesis1_has31Verses() {
        let ch = db.chapter(translation: .rv1960, bookId: 1, number: 1)
        XCTAssertEqual(ch?.verses.count, 31)
    }

    func testChapter_versesStartAtOne() {
        let ch = db.chapter(translation: .rv1960, bookId: 1, number: 1)
        XCTAssertEqual(ch?.verses.first?.number, 1)
    }

    func testChapter_versesAreOrdered() {
        let verses = db.chapter(translation: .rv1960, bookId: 1, number: 1)?.verses ?? []
        let numbers = verses.map(\.number)
        XCTAssertEqual(numbers, numbers.sorted())
    }

    func testChapter_noVerseHasEmptyText() {
        let verses = db.chapter(translation: .rv1960, bookId: 1, number: 1)?.verses ?? []
        XCTAssertTrue(verses.allSatisfy { !$0.text.isEmpty })
    }

    func testChapter_invalidBookId_returnsNil() {
        XCTAssertNil(db.chapter(translation: .rv1960, bookId: 999, number: 1))
    }

    func testChapter_invalidChapterNumber_returnsNil() {
        XCTAssertNil(db.chapter(translation: .rv1960, bookId: 1, number: 999))
    }

    func testChapter_cornilescu_genesis1_hasVerses() {
        let ch = db.chapter(translation: .cornilescu, bookId: 1, number: 1)
        XCTAssertNotNil(ch)
        XCTAssertGreaterThan(ch!.verses.count, 0)
    }

    func testChapter_john3_hasVerse16() {
        // John is book 43 in standard numbering
        let books = db.books(for: .rv1960)
        guard let john = books.first(where: { $0.name.lowercased().contains("juan") }) else {
            return XCTFail("Juan not found")
        }
        let ch = db.chapter(translation: .rv1960, bookId: john.id, number: 3)
        XCTAssertNotNil(ch?.verses.first(where: { $0.number == 16 }))
    }

    // MARK: - verseOfDay()

    func testVerseOfDay_returnsSomething() {
        let v = db.verseOfDay(translation: .rv1960, seed: 42)
        XCTAssertNotNil(v)
    }

    func testVerseOfDay_textIsNonEmpty() {
        let v = db.verseOfDay(translation: .rv1960, seed: 42)
        XCTAssertFalse(v?.text.isEmpty ?? true)
    }

    func testVerseOfDay_sameSeedIsDeterministic() {
        let v1 = db.verseOfDay(translation: .rv1960, seed: 100)
        let v2 = db.verseOfDay(translation: .rv1960, seed: 100)
        XCTAssertEqual(v1?.bookId,  v2?.bookId)
        XCTAssertEqual(v1?.chapter, v2?.chapter)
        XCTAssertEqual(v1?.verse,   v2?.verse)
    }

    func testVerseOfDay_consecutiveSeedsGiveDifferentVerses() {
        let v1 = db.verseOfDay(translation: .rv1960, seed: 0)
        let v2 = db.verseOfDay(translation: .rv1960, seed: 1)
        let same = v1?.bookId  == v2?.bookId  &&
                   v1?.chapter == v2?.chapter &&
                   v1?.verse   == v2?.verse
        XCTAssertFalse(same, "Seeds 0 and 1 should map to different verses")
    }

    func testVerseOfDay_bookIdInValidRange() {
        let v = db.verseOfDay(translation: .rv1960, seed: 777)
        XCTAssertTrue((1...66).contains(v!.bookId))
    }

    func testVerseOfDay_cornilescu_works() {
        XCTAssertNotNil(db.verseOfDay(translation: .cornilescu, seed: 42))
    }

    // MARK: - search()

    func testSearch_commonWord_returnsResults() {
        let results = db.search(translation: .rv1960, query: "Dios")
        XCTAssertGreaterThan(results.count, 0)
    }

    func testSearch_emptyQuery_returnsEmpty() {
        XCTAssertTrue(db.search(translation: .rv1960, query: "").isEmpty)
    }

    func testSearch_whitespaceOnly_returnsEmpty() {
        XCTAssertTrue(db.search(translation: .rv1960, query: "   ").isEmpty)
    }

    func testSearch_defaultLimitIs200() {
        let results = db.search(translation: .rv1960, query: "y")
        XCTAssertLessThanOrEqual(results.count, 200)
    }

    func testSearch_customLimitRespected() {
        let results = db.search(translation: .rv1960, query: "Dios", limit: 5)
        XCTAssertLessThanOrEqual(results.count, 5)
    }

    func testSearch_resultsContainQuery() {
        let results = db.search(translation: .rv1960, query: "amor")
        XCTAssertTrue(results.allSatisfy { $0.text.lowercased().contains("amor") })
    }

    func testSearch_allBookIdsInRange() {
        let results = db.search(translation: .rv1960, query: "Dios")
        XCTAssertTrue(results.allSatisfy { (1...66).contains($0.bookId) })
    }

    func testSearch_allChaptersPositive() {
        let results = db.search(translation: .rv1960, query: "Dios")
        XCTAssertTrue(results.allSatisfy { $0.chapter > 0 })
    }

    func testSearch_allVersesPositive() {
        let results = db.search(translation: .rv1960, query: "Dios")
        XCTAssertTrue(results.allSatisfy { $0.verse > 0 })
    }

    func testSearch_bookNameIsNonEmpty() {
        let results = db.search(translation: .rv1960, query: "amor")
        XCTAssertTrue(results.allSatisfy { !$0.bookName.isEmpty })
    }

    func testSearch_cornilescu_works() {
        let results = db.search(translation: .cornilescu, query: "Dumnezeu")
        XCTAssertGreaterThan(results.count, 0)
    }

    func testSearch_percentEscaped_doesNotMatchAll() {
        // If % were not escaped it would match every row; escaping means it finds literal %
        let results = db.search(translation: .rv1960, query: "%")
        XCTAssertEqual(results.count, 0, "Bible text should not contain literal % characters")
    }

    func testSearch_sqlSpecialChars_doesNotCrash() {
        // Parameterized query — injection not possible; just must not crash
        let results = db.search(translation: .rv1960, query: "' OR '1'='1")
        XCTAssertLessThanOrEqual(results.count, 200)
    }
}
