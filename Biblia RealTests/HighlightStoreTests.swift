import XCTest
@testable import Biblia_Real

final class HighlightStoreTests: XCTestCase {
    let store = HighlightStore.shared
    let udKey = "verseHighlights_v1"

    // Coordinates for two test verses that we clean up before/after every test
    private let t1 = Translation.rv1960
    private let b1 = 1, c1 = 1, v1 = 1
    private let b2 = 1, c2 = 1, v2 = 2
    private let t2 = Translation.cornilescu

    override func setUp() {
        super.setUp()
        store.set(nil, translation: t1,  bookId: b1, chapter: c1, verse: v1)
        store.set(nil, translation: t1,  bookId: b1, chapter: c1, verse: v2)
        store.set(nil, translation: t2,  bookId: b1, chapter: c1, verse: v1)
    }

    override func tearDown() {
        super.tearDown()
        store.set(nil, translation: t1,  bookId: b1, chapter: c1, verse: v1)
        store.set(nil, translation: t1,  bookId: b1, chapter: c1, verse: v2)
        store.set(nil, translation: t2,  bookId: b1, chapter: c1, verse: v1)
    }

    // MARK: - set / color

    func testSet_storesColor() {
        store.set(.yellow, translation: t1, bookId: b1, chapter: c1, verse: v1)
        XCTAssertEqual(store.color(translation: t1, bookId: b1, chapter: c1, verse: v1), .yellow)
    }

    func testSet_overwritesPreviousColor() {
        store.set(.yellow, translation: t1, bookId: b1, chapter: c1, verse: v1)
        store.set(.blue,   translation: t1, bookId: b1, chapter: c1, verse: v1)
        XCTAssertEqual(store.color(translation: t1, bookId: b1, chapter: c1, verse: v1), .blue)
    }

    func testSet_nil_removesHighlight() {
        store.set(.green, translation: t1, bookId: b1, chapter: c1, verse: v1)
        store.set(nil,    translation: t1, bookId: b1, chapter: c1, verse: v1)
        XCTAssertNil(store.color(translation: t1, bookId: b1, chapter: c1, verse: v1))
    }

    func testColor_unhighlightedVerse_returnsNil() {
        XCTAssertNil(store.color(translation: t1, bookId: b1, chapter: c1, verse: v1))
    }

    func testSet_twoVerses_dontInterfere() {
        store.set(.yellow, translation: t1, bookId: b1, chapter: c1, verse: v1)
        store.set(.green,  translation: t1, bookId: b1, chapter: c1, verse: v2)
        XCTAssertEqual(store.color(translation: t1, bookId: b1, chapter: c1, verse: v1), .yellow)
        XCTAssertEqual(store.color(translation: t1, bookId: b1, chapter: c1, verse: v2), .green)
    }

    func testSet_differentTranslations_dontInterfere() {
        store.set(.yellow, translation: t1, bookId: b1, chapter: c1, verse: v1)
        store.set(.pink,   translation: t2, bookId: b1, chapter: c1, verse: v1)
        XCTAssertEqual(store.color(translation: t1, bookId: b1, chapter: c1, verse: v1), .yellow)
        XCTAssertEqual(store.color(translation: t2, bookId: b1, chapter: c1, verse: v1), .pink)
    }

    func testSet_onlyOneEntryPerVerse() {
        store.set(.yellow, translation: t1, bookId: b1, chapter: c1, verse: v1)
        store.set(.blue,   translation: t1, bookId: b1, chapter: c1, verse: v1)
        let matches = store.highlights.filter {
            $0.translation == t1.rawValue && $0.bookId == b1 && $0.chapter == c1 && $0.verse == v1
        }
        XCTAssertEqual(matches.count, 1)
    }

    // MARK: - persistence

    func testSet_persistsToUserDefaults() {
        store.set(.green, translation: t1, bookId: b1, chapter: c1, verse: v1)
        guard let data = UserDefaults.standard.data(forKey: udKey) else {
            return XCTFail("No data in UserDefaults after set()")
        }
        let decoded = try? JSONDecoder().decode([VerseHighlight].self, from: data)
        XCTAssertNotNil(decoded)
        let match = decoded!.first {
            $0.translation == t1.rawValue && $0.bookId == b1 && $0.chapter == c1 && $0.verse == v1
        }
        XCTAssertEqual(match?.color, .green)
    }

    func testRemove_reflectedInUserDefaults() {
        store.set(.yellow, translation: t1, bookId: b1, chapter: c1, verse: v1)
        store.set(nil,     translation: t1, bookId: b1, chapter: c1, verse: v1)
        if let data = UserDefaults.standard.data(forKey: udKey),
           let decoded = try? JSONDecoder().decode([VerseHighlight].self, from: data) {
            let match = decoded.first {
                $0.translation == t1.rawValue && $0.bookId == b1 && $0.chapter == c1 && $0.verse == v1
            }
            XCTAssertNil(match)
        }
    }

    // MARK: - HighlightColor enum

    func testAllColors_haveNonEmptyLabels_rv1960() {
        for hc in HighlightColor.allCases {
            XCTAssertFalse(hc.label(for: .rv1960).isEmpty, "\(hc) label is empty for rv1960")
        }
    }

    func testAllColors_haveNonEmptyLabels_cornilescu() {
        for hc in HighlightColor.allCases {
            XCTAssertFalse(hc.label(for: .cornilescu).isEmpty, "\(hc) label is empty for cornilescu")
        }
    }

    func testHighlightColor_has4Cases() {
        XCTAssertEqual(HighlightColor.allCases.count, 4)
    }

    func testHighlightColor_rawValues_matchCaseNames() {
        XCTAssertEqual(HighlightColor.yellow.rawValue, "yellow")
        XCTAssertEqual(HighlightColor.green.rawValue,  "green")
        XCTAssertEqual(HighlightColor.pink.rawValue,   "pink")
        XCTAssertEqual(HighlightColor.blue.rawValue,   "blue")
    }
}
