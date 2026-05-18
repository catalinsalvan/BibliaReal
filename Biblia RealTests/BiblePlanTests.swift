import XCTest
@testable import Biblia_Real

final class BiblePlanTests: XCTestCase {
    let plan = BiblePlan.fiveDayWeek

    // MARK: - Plan shape

    func testPlan_has260Days() {
        XCTAssertEqual(plan.count, 260)
    }

    func testPlan_dayNumbersAreSequential1to260() {
        XCTAssertEqual(plan.map(\.day), Array(1...260))
    }

    func testPlan_allDaysHaveAtLeastOnePassage() {
        XCTAssertTrue(plan.allSatisfy { !$0.passages.isEmpty })
    }

    // MARK: - Passage integrity

    func testPlan_allPassagesHaveChapters() {
        let bad = plan.flatMap(\.passages).filter { $0.chapters.isEmpty }
        XCTAssertTrue(bad.isEmpty, "Days with empty chapter list: \(bad.map(\.bookId))")
    }

    func testPlan_allBookIdsInValidRange() {
        let bad = plan.flatMap(\.passages).filter { !((1...66).contains($0.bookId)) }
        XCTAssertTrue(bad.isEmpty, "Invalid bookIds: \(bad.map(\.bookId))")
    }

    func testPlan_allChapterNumbersArePositive() {
        let bad = plan.flatMap(\.passages).filter { $0.chapters.contains { $0 <= 0 } }
        XCTAssertTrue(bad.isEmpty)
    }

    // MARK: - Bookends

    func testPlan_day1_includesGenesis() {
        XCTAssertTrue(plan[0].passages.contains { $0.bookId == 1 }, "Day 1 should include Genesis (bookId 1)")
    }

    func testPlan_lastDay_includesRevelation() {
        XCTAssertTrue(plan[259].passages.contains { $0.bookId == 66 }, "Day 260 should include Revelation (bookId 66)")
    }

    func testPlan_lastDay_includesPsalm150() {
        let psalms = plan[259].passages.first { $0.bookId == 19 }
        XCTAssertNotNil(psalms)
        XCTAssertTrue(psalms!.chapters.contains(150), "Day 260 should include Psalm 150")
    }

    // MARK: - PlanPassage.label()

    func testLabel_singleChapter() {
        let p = PlanPassage(bookId: 1, chapters: [3])
        XCTAssertEqual(p.label(using: [1: "Génesis"]), "Génesis 3")
    }

    func testLabel_consecutiveRange() {
        let p = PlanPassage(bookId: 1, chapters: [1, 2, 3])
        XCTAssertEqual(p.label(using: [1: "Génesis"]), "Génesis 1 – 3")
    }

    func testLabel_nonConsecutive() {
        let p = PlanPassage(bookId: 1, chapters: [1, 3, 5])
        XCTAssertEqual(p.label(using: [1: "Génesis"]), "Génesis 1, 3, 5")
    }

    func testLabel_unknownBookId_usesHashFallback() {
        let p = PlanPassage(bookId: 999, chapters: [1])
        XCTAssertEqual(p.label(using: [:]), "#999 1")
    }

    func testLabel_emptyChapters_returnsBookNameOnly() {
        let p = PlanPassage(bookId: 1, chapters: [])
        XCTAssertEqual(p.label(using: [1: "Génesis"]), "Génesis")
    }

    // MARK: - PlanPassage.firstChapter

    func testFirstChapter_returnsFirstElement() {
        let p = PlanPassage(bookId: 1, chapters: [5, 6, 7])
        XCTAssertEqual(p.firstChapter, 5)
    }

    func testFirstChapter_emptyChapters_returnsDefault1() {
        let p = PlanPassage(bookId: 1, chapters: [])
        XCTAssertEqual(p.firstChapter, 1)
    }

    // MARK: - PlanDay

    func testPlanDay_dayNumberMatchesIndex() {
        for (i, day) in plan.enumerated() {
            XCTAssertEqual(day.day, i + 1, "Day at index \(i) has wrong day number \(day.day)")
        }
    }
}
