import XCTest
import PencilKit
@testable import Biblia_Real

final class AnnotationStoreTests: XCTestCase {
    // Create a fresh instance (AnnotationStore.init() is not private)
    let store = AnnotationStore()

    // Use a key that won't collide with real annotation data
    private let key = "unit_test_annotation_key_DO_NOT_USE"

    private var annotationsDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("annotations", isDirectory: true)
    }

    override func tearDown() {
        super.tearDown()
        for suffix in ["overlay", "margin"] {
            let url = annotationsDir.appendingPathComponent("\(key)_\(suffix).pkd")
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - load (no prior save)

    func testLoad_nonExistentKey_returnsEmptyOverlay() {
        let result = store.load(key: key)
        XCTAssertEqual(result.overlay.strokes.count, 0)
    }

    func testLoad_nonExistentKey_returnsEmptyMargin() {
        let result = store.load(key: key)
        XCTAssertEqual(result.margin.strokes.count, 0)
    }

    // MARK: - save then load

    func testSaveAndLoad_emptyDrawings_roundTrip() {
        store.save(key: key, overlay: PKDrawing(), margin: PKDrawing())
        let result = store.load(key: key)
        XCTAssertEqual(result.overlay.strokes.count, 0)
        XCTAssertEqual(result.margin.strokes.count, 0)
    }

    func testSave_createsOverlayFile() {
        store.save(key: key, overlay: PKDrawing(), margin: PKDrawing())
        let path = annotationsDir.appendingPathComponent("\(key)_overlay.pkd").path
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func testSave_createsMarginFile() {
        store.save(key: key, overlay: PKDrawing(), margin: PKDrawing())
        let path = annotationsDir.appendingPathComponent("\(key)_margin.pkd").path
        XCTAssertTrue(FileManager.default.fileExists(atPath: path))
    }

    func testSave_overwritesPreviousSave() {
        store.save(key: key, overlay: PKDrawing(), margin: PKDrawing())
        store.save(key: key, overlay: PKDrawing(), margin: PKDrawing())
        let result = store.load(key: key)
        XCTAssertEqual(result.overlay.strokes.count, 0)
        XCTAssertEqual(result.margin.strokes.count, 0)
    }

    func testSave_differentKeys_independent() {
        let key2 = "\(key)_2"
        defer {
            for suffix in ["overlay", "margin"] {
                let url = annotationsDir.appendingPathComponent("\(key2)_\(suffix).pkd")
                try? FileManager.default.removeItem(at: url)
            }
        }

        store.save(key: key,  overlay: PKDrawing(), margin: PKDrawing())
        store.save(key: key2, overlay: PKDrawing(), margin: PKDrawing())

        let r1 = store.load(key: key)
        let r2 = store.load(key: key2)
        XCTAssertEqual(r1.overlay.strokes.count, 0)
        XCTAssertEqual(r2.overlay.strokes.count, 0)
    }
}
