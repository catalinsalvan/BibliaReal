import Foundation
import PencilKit

class AnnotationStore {
    static let shared = AnnotationStore()

    private let baseURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("annotations", isDirectory: true)
    }()

    init() {
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    func save(key: String, overlay: PKDrawing, margin: PKDrawing) {
        try? overlay.dataRepresentation().write(to: fileURL(key, "overlay"))
        try? margin.dataRepresentation().write(to: fileURL(key, "margin"))
    }

    func load(key: String) -> (overlay: PKDrawing, margin: PKDrawing) {
        (loadDrawing(fileURL(key, "overlay")), loadDrawing(fileURL(key, "margin")))
    }

    private func fileURL(_ key: String, _ suffix: String) -> URL {
        baseURL.appendingPathComponent("\(key)_\(suffix).pkd")
    }

    private func loadDrawing(_ url: URL) -> PKDrawing {
        guard let data = try? Data(contentsOf: url),
              let drawing = try? PKDrawing(data: data) else { return PKDrawing() }
        return drawing
    }
}
