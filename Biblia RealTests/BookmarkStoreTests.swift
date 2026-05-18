import XCTest
@testable import Biblia_Real

final class BookmarkStoreTests: XCTestCase {
    let store = BookmarkStore.shared
    let udKey = "bookmarks_v1"

    // Test coordinates — unlikely to collide with real user data
    private let t1 = Translation.rv1960
    private let t2 = Translation.cornilescu
    private let bid = 1, bname = "TestGenesis"
    private let ch1 = 999, ch2 = 998   // chapter numbers that don't exist in the real Bible

    override func setUp() {
        super.setUp()
        cleanup()
    }

    override func tearDown() {
        super.tearDown()
        cleanup()
    }

    private func cleanup() {
        if store.isBookmarked(translation: t1, bookId: bid, chapter: ch1) {
            store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        }
        if store.isBookmarked(translation: t1, bookId: bid, chapter: ch2) {
            store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch2)
        }
        if store.isBookmarked(translation: t2, bookId: bid, chapter: ch1) {
            store.toggle(translation: t2, bookId: bid, bookName: bname, chapter: ch1)
        }
    }

    // MARK: - toggle / isBookmarked

    func testToggle_addsBookmark() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        XCTAssertTrue(store.isBookmarked(translation: t1, bookId: bid, chapter: ch1))
    }

    func testToggle_removesExistingBookmark() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        XCTAssertFalse(store.isBookmarked(translation: t1, bookId: bid, chapter: ch1))
    }

    func testIsBookmarked_whenNotPresent_returnsFalse() {
        XCTAssertFalse(store.isBookmarked(translation: t1, bookId: bid, chapter: ch1))
    }

    func testToggle_incrementsCount() {
        let before = store.bookmarks.count
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        XCTAssertEqual(store.bookmarks.count, before + 1)
    }

    func testToggle_decrementsCount() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        let before = store.bookmarks.count
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        XCTAssertEqual(store.bookmarks.count, before - 1)
    }

    func testToggle_twoDifferentChapters_bothPresent() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch2)
        XCTAssertTrue(store.isBookmarked(translation: t1, bookId: bid, chapter: ch1))
        XCTAssertTrue(store.isBookmarked(translation: t1, bookId: bid, chapter: ch2))
    }

    func testToggle_differentTranslations_independent() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        XCTAssertFalse(store.isBookmarked(translation: t2, bookId: bid, chapter: ch1))
    }

    // MARK: - Bookmark properties

    func testBookmark_hasCorrectTranslation() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        let bm = store.bookmarks.first { $0.bookId == bid && $0.chapter == ch1 }
        XCTAssertEqual(bm?.translation, t1.rawValue)
    }

    func testBookmark_hasCorrectBookName() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        let bm = store.bookmarks.first { $0.bookId == bid && $0.chapter == ch1 }
        XCTAssertEqual(bm?.bookName, bname)
    }

    func testBookmark_labelFormatted() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        let bm = store.bookmarks.first { $0.bookId == bid && $0.chapter == ch1 }
        XCTAssertEqual(bm?.label, "\(bname) \(ch1)")
    }

    func testBookmark_addedAtIsRecent() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        let bm = store.bookmarks.first { $0.bookId == bid && $0.chapter == ch1 }
        XCTAssertNotNil(bm?.addedAt)
        XCTAssertLessThan(bm!.addedAt.timeIntervalSinceNow, 5)
    }

    // MARK: - remove(at:)

    func testRemove_atOffsets_removesCorrectEntry() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        guard let idx = store.bookmarks.firstIndex(where: { $0.bookId == bid && $0.chapter == ch1 }) else {
            return XCTFail("Bookmark not found after toggle")
        }
        let before = store.bookmarks.count
        store.remove(at: IndexSet(integer: idx))
        XCTAssertEqual(store.bookmarks.count, before - 1)
        XCTAssertFalse(store.isBookmarked(translation: t1, bookId: bid, chapter: ch1))
    }

    // MARK: - persistence

    func testToggle_persistsToUserDefaults() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        guard let data = UserDefaults.standard.data(forKey: udKey) else {
            return XCTFail("No data in UserDefaults after toggle()")
        }
        let decoded = try? JSONDecoder().decode([Bookmark].self, from: data)
        XCTAssertNotNil(decoded)
        XCTAssertTrue(decoded!.contains { $0.bookId == bid && $0.chapter == ch1 })
    }

    func testRemove_reflectedInUserDefaults() {
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        store.toggle(translation: t1, bookId: bid, bookName: bname, chapter: ch1)
        if let data = UserDefaults.standard.data(forKey: udKey),
           let decoded = try? JSONDecoder().decode([Bookmark].self, from: data) {
            XCTAssertFalse(decoded.contains { $0.bookId == bid && $0.chapter == ch1 })
        }
    }
}
